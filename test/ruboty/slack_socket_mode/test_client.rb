require 'test_helper'

class TestSlackSocketModeClient < Test::Unit::TestCase
  Frame = Struct.new(:type, :data)

  # Stands in for WebSocket::Client::Simple::Client: same event names, and
  # listeners run through EventEmitter's instance_exec like the real one.
  class FakeWebSocket
    include EventEmitter

    attr_reader :sent, :thread
    attr_accessor :on_send

    def initialize
      @sent = []
      @closed = false
      @thread = Thread.new { sleep }
    end

    def send(data, opt = { type: :text })
      on_send&.call(data, opt[:type])
      @sent << [opt[:type], data]
    end

    def close
      raise Errno::ECONNRESET, 'SSL_write' if @raise_on_close

      @closed = true
      @thread.kill
      emit :close
    end

    def raise_on_close!
      @raise_on_close = true
    end

    def closed?
      @closed
    end
  end

  setup do
    @original_logger = Ruboty.instance_variable_get(:@logger)
    @log = StringIO.new
    Ruboty.instance_variable_set(:@logger, Logger.new(@log))
    @ws = FakeWebSocket.new
    @received = Queue.new
  end

  teardown do
    Ruboty.instance_variable_set(:@logger, @original_logger)
    @ws.thread.kill
  end

  def build_client(**options)
    defaults = { ping_interval: 60, idle_timeout: 60, watchdog_interval: 0.05 }
    client = Ruboty::SlackSocketMode::Client.new(
      websocket_url: 'wss://example.invalid/link',
      websocket_factory: lambda { |_url, &setup|
        setup&.call(@ws)
        @ws
      },
      **defaults.merge(options)
    )
    client.on_text { |data| @received << data }
    client
  end

  # Runs main_loop in a thread and returns it; main_loop must return by itself.
  def run_main_loop(client)
    Thread.new { client.main_loop }
  end

  def assert_main_loop_returns(thread, timeout: 3)
    assert_not_nil thread.join(timeout), 'main_loop did not return after the connection was lost'
  end

  def wait_until(timeout: 3)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    until yield
      return false if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      sleep 0.01
    end
    true
  end

  def text_frame(payload)
    Frame.new(:text, payload.to_json)
  end

  test 'returns from main_loop when replying to a ping raises ECONNRESET' do
    client = build_client
    @ws.on_send = ->(_data, type) { raise Errno::ECONNRESET, 'SSL_write' if type == :pong }
    thread = run_main_loop(client)

    @ws.emit :message, Frame.new(:ping, '')

    assert_main_loop_returns(thread)
    assert_match(/ECONNRESET/, client.disconnect_reason)
    assert_true @ws.closed?
  end

  test 'returns from main_loop when the connection is closed' do
    client = build_client
    thread = run_main_loop(client)

    @ws.emit :close, nil

    assert_main_loop_returns(thread)
    assert_match(/connection closed/, client.disconnect_reason)
  end

  test 'returns from main_loop when the connection reports an error' do
    client = build_client
    thread = run_main_loop(client)

    @ws.emit :error, Errno::ECONNRESET.new('read')

    assert_main_loop_returns(thread)
    assert_match(/ECONNRESET/, client.disconnect_reason)
  end

  test 'returns from main_loop when nothing arrives for the idle timeout' do
    client = build_client(idle_timeout: 0.3)
    thread = run_main_loop(client)

    assert_main_loop_returns(thread)
    assert_match(/nothing received/, client.disconnect_reason)
  end

  test 'keeps the connection while pongs answer the pings' do
    client = build_client(ping_interval: 0.1, idle_timeout: 0.5)
    @ws.on_send = ->(_data, type) { @ws.emit(:message, Frame.new(:pong, '')) if type == :ping }
    thread = run_main_loop(client)

    assert_nil thread.join(1.5), 'main_loop returned although pongs kept arriving'
    assert_false client.disconnected?
  ensure
    client&.disconnect('test finished')
    thread&.join(3)
  end

  test 'returns from main_loop when Slack sends a close frame' do
    client = build_client
    thread = run_main_loop(client)

    @ws.emit :message, Frame.new(:close, '')

    assert_main_loop_returns(thread)
  end

  test 'acks events with JSON and passes them on' do
    client = build_client
    thread = run_main_loop(client)

    @ws.emit :message, text_frame('type' => 'events_api', 'envelope_id' => 'env-1', 'payload' => {})

    assert_equal 'events_api', @received.pop['type']
    assert_true wait_until { @ws.sent.include?([:text, '{"envelope_id":"env-1"}']) }
  ensure
    client&.disconnect('test finished')
    thread&.join(3)
  end

  test 'starts reconnecting when Slack asks to disconnect' do
    client = build_client
    thread = run_main_loop(client)

    @ws.emit :message, text_frame('type' => 'disconnect', 'reason' => 'refresh_requested')

    assert_main_loop_returns(thread)
    assert_match(/refresh_requested/, client.disconnect_reason)
    assert_equal 'disconnect', @received.pop['type']
  end

  test 'stops the reader thread even if closing the websocket raises' do
    client = build_client
    @ws.raise_on_close!
    thread = run_main_loop(client)

    @ws.emit :close, nil

    assert_main_loop_returns(thread)
    assert_not_nil @ws.thread.join(1), 'reader thread is still running'
  end

  test 'writes acks and pongs outside the thread that receives frames' do
    client = build_client
    writers = Queue.new
    @ws.on_send = ->(_data, _type) { writers << Thread.current }
    thread = run_main_loop(client)

    receiver = Thread.new { @ws.emit :message, Frame.new(:ping, '') }
    receiver.join

    assert_equal thread, writers.pop
  ensure
    client&.disconnect('test finished')
    thread&.join(3)
  end

  # With the real websocket-client-simple, a write failing with EPIPE closes
  # the connection and kills the reader thread before :close is emitted.
  test 'notices a write that fails with EPIPE in the real websocket client' do
    broken_socket = Object.new
    def broken_socket.write(_data) = raise(Errno::EPIPE)
    def broken_socket.close; end

    ws = WebSocket::Client::Simple::Client.new
    {
      handshaked: true, closed: false, pipe_broken: false,
      handshake: Struct.new(:version).new(13), socket: broken_socket
    }.each { |name, value| ws.instance_variable_set(:"@#{name}", value) }
    start = Queue.new
    reader = Thread.new do
      start.pop
      ws.emit(:message, Frame.new(:ping, ''))
    end
    ws.instance_variable_set(:@thread, reader)
    ws.once(:__close) do |err|
      close
      emit :close, err
    end

    client = Ruboty::SlackSocketMode::Client.new(
      websocket_url: 'wss://example.invalid/link',
      websocket_factory: lambda { |_url, &setup|
        setup&.call(ws)
        ws
      },
      ping_interval: 60, idle_timeout: 60, watchdog_interval: 0.05
    )
    client.on_text { |_data| }
    thread = run_main_loop(client)
    start << true

    assert_main_loop_returns(thread)
    assert_match(/connection closed .*EPIPE/, client.disconnect_reason)
  ensure
    reader&.kill
  end

  test 'logs only the first error after the connection broke' do
    client = build_client
    thread = run_main_loop(client)

    3.times { @ws.emit :error, Errno::ECONNRESET.new('read') }

    assert_main_loop_returns(thread)
    assert_equal 1, @log.string.scan(/^E, .*ECONNRESET/).size
  end
end
