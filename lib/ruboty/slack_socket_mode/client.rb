require 'json'
require 'timeout'
require 'websocket-client-simple'

module Ruboty
  module SlackSocketMode
    class Client
      CONNECTION_CLOSED = Object.new

      PING_INTERVAL = 30
      # Slack answers our pings with pongs, so silence for several ping
      # intervals means the connection is gone even if no error was raised.
      IDLE_TIMEOUT = 90
      WATCHDOG_INTERVAL = 5
      CONNECT_TIMEOUT = 30

      def initialize(websocket_url:, ping_interval: PING_INTERVAL, idle_timeout: IDLE_TIMEOUT,
                     watchdog_interval: WATCHDOG_INTERVAL, connect_timeout: CONNECT_TIMEOUT,
                     websocket_factory: nil)
        @queue = Queue.new
        @state_lock = Mutex.new
        @ping_interval = ping_interval
        @idle_timeout = idle_timeout
        @watchdog_interval = watchdog_interval
        @disconnect_reason = nil
        @closed = false
        touch
        factory = websocket_factory || method(:connect_websocket)
        # websocket-client-simple has no connect timeout of its own.
        @client = Timeout.timeout(connect_timeout) do
          factory.call(websocket_url.to_s) { |ws| register_connection_listeners(ws) }
        end
      end

      attr_reader :disconnect_reason

      def send_message(data)
        data[:id] = (Time.now.to_i * 10 + rand(10)) % (1 << 31)
        @queue.enq([data.to_json, :text])
      end

      def on_text(&block)
        this = self
        @client.on(:message) do |message|
          # EventEmitter runs this block via instance_exec, so `self` is the
          # websocket client here.
          this.__send__(:handle_frame, message, &block)
        end
      end

      # Returns when the connection is lost or closed. The caller decides
      # whether to open a new connection.
      #
      # Every write happens on this thread. When a write fails with EPIPE or
      # SSLError, websocket-client-simple closes the connection and kills its
      # reader thread before emitting :close, so a write made on the reader
      # thread would end that thread silently and nobody would notice.
      def main_loop
        watchdog = start_watchdog

        loop do
          item = @queue.deq
          break if item.equal?(CONNECTION_CLOSED)

          data, type = item
          write(data, type: type)
        end
      ensure
        watchdog&.kill
        close
      end

      def disconnect(reason)
        first = @state_lock.synchronize do
          next false if @disconnect_reason

          @disconnect_reason = reason
          true
        end
        return unless first

        Ruboty.logger.warn("#{Client.name}: Disconnecting: #{reason}")
        @queue.enq(CONNECTION_CLOSED)
      end

      def disconnected?
        !@disconnect_reason.nil?
      end

      private

      def connect_websocket(url, &setup)
        WebSocket::Client::Simple.connect(url, verify_mode: OpenSSL::SSL::VERIFY_PEER, &setup)
      end

      # Called before the connection starts so no error or close is missed.
      def register_connection_listeners(websocket)
        this = self
        websocket.on(:error) do |err|
          this.__send__(:on_connection_error, err)
        end
        websocket.on(:close) do |err|
          this.disconnect("connection closed#{err ? " (#{err.class}: #{err.message})" : ''}")
        end
      end

      def on_connection_error(err)
        # After the connection breaks, websocket-client-simple keeps reading
        # the dead socket and emits the same error until we close it.
        if disconnected?
          Ruboty.logger.debug("#{Client.name}: #{err.class}: #{err.message}")
          return
        end

        Ruboty.logger.error("#{err.class}: #{err.message}\n#{Array(err.backtrace).join("\n")}")
        disconnect("#{err.class}: #{err.message}")
      end

      def handle_frame(message, &block)
        touch

        case message.type
        when :ping
          Ruboty.logger.debug("#{Client.name}: Received ping message")
          enqueue_write(message.data.to_s, :pong)
        when :pong
          Ruboty.logger.debug("#{Client.name}: Received pong message")
        when :close
          disconnect('close frame received')
        when :text
          data = JSON.parse(message.data)
          Ruboty.logger.debug("#{Client.name}: Received text message: #{data}")

          # ACK response for SocketMode
          # ref: https://api.slack.com/apis/connections/socket-implement#acknowledge
          enqueue_write({ 'envelope_id' => data['envelope_id'] }.to_json, :text) if data['envelope_id']

          if data['type'] == 'disconnect'
            # Slack closes this connection shortly; switch before it does.
            disconnect("disconnect requested by Slack (reason=#{data['reason']})")
          end

          block&.call(data)
        else
          Ruboty.logger.warn("#{Client.name}: Received unknown message type=#{message.type}: #{message.data}")
        end
      rescue StandardError => e
        Ruboty.logger.error("#{e.class}: #{e.message}\n#{Array(e.backtrace).join("\n")}")
      end

      def enqueue_write(data, type)
        @queue.enq([data, type])
      end

      def write(data, type: :text)
        @client.send(data, type: type)
        # send returns quietly once the library has closed the connection.
        disconnect('websocket closed') if websocket_closed?
      rescue StandardError => e
        # websocket-client-simple only turns EPIPE and SSLError into a close
        # event; ECONNRESET and others are raised to the caller.
        disconnect("write failed (#{e.class}: #{e.message})")
      end

      def websocket_closed?
        @client.respond_to?(:closed?) && @client.closed?
      end

      def reader_stopped?
        reader = @client.respond_to?(:thread) ? @client.thread : nil
        !reader.nil? && !reader.alive?
      end

      def touch
        @last_received_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def idle_seconds
        Process.clock_gettime(Process::CLOCK_MONOTONIC) - @last_received_at
      end

      def start_watchdog
        Thread.start do
          last_ping_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          until disconnected?
            sleep(@watchdog_interval)

            if websocket_closed? || reader_stopped?
              disconnect('websocket closed or its reader thread stopped')
              break
            end

            idle = idle_seconds
            if idle > @idle_timeout
              disconnect(format('nothing received for %d seconds', idle))
              break
            end

            now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            if now - last_ping_at >= @ping_interval
              last_ping_at = now
              enqueue_write('', :ping)
            end
          end
        rescue StandardError => e
          Ruboty.logger.error("#{e.class}: #{e.message}\n#{Array(e.backtrace).join("\n")}")
          disconnect("watchdog failed (#{e.class}: #{e.message})")
        end
      end

      def close
        return if @closed

        @closed = true
        begin
          @client.close
        rescue StandardError => e
          # Writing the close frame fails on a reset connection, which leaves
          # the reader thread running; stop it directly.
          Ruboty.logger.debug("#{Client.name}: close failed: #{e.class}: #{e.message}")
          close_raw_socket
        end
        reader = @client.respond_to?(:thread) ? @client.thread : nil
        reader.kill if reader&.alive? && reader != Thread.current
      end

      # The library stops before closing its socket when writing the close
      # frame fails, which would leave the descriptor open until GC.
      def close_raw_socket
        raw = @client.instance_variable_get(:@socket)
        raw&.close
      rescue StandardError
        nil
      end
    end
  end
end
