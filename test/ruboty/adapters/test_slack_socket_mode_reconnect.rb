require 'test_helper'
require 'socket'
require 'websocket'

# Runs the adapter against a local WebSocket server (plain ws://) so the real
# websocket-client-simple read loop is exercised when connections go bad.
class TestSlackSocketModeReconnect < Test::Unit::TestCase
  class FakeSlackServer
    Connection = Struct.new(:socket, :incoming)

    def initialize
      @server = TCPServer.new('127.0.0.1', 0)
      @connections = Queue.new
      @acks = Queue.new
      @answer_pings = true
      @accept_thread = Thread.new { accept_loop }
    end

    attr_reader :acks
    attr_accessor :answer_pings

    def url
      URI.parse("ws://127.0.0.1:#{@server.addr[1]}/link")
    end

    def next_connection(timeout: 5)
      @connections.pop(timeout: timeout) or raise 'client did not connect'
    end

    def send_event(conn, payload)
      frame = WebSocket::Frame::Outgoing::Server.new(version: 13, data: payload.to_json, type: :text)
      conn.socket.write(frame.to_s)
    end

    def stop
      @accept_thread.kill
      @server.close
    end

    private

    def accept_loop
      loop do
        socket = @server.accept
        Thread.new(socket) { |s| serve(s) }
      end
    end

    def serve(socket)
      handshake = WebSocket::Handshake::Server.new
      handshake << socket.readpartial(4096) until handshake.finished?
      socket.write(handshake.to_s)
      conn = Connection.new(socket, WebSocket::Frame::Incoming::Server.new(version: handshake.version))
      @connections << conn
      loop do
        conn.incoming << socket.readpartial(4096)
        while (frame = conn.incoming.next)
          case frame.type
          when :text
            @acks << JSON.parse(frame.data)
          when :ping
            next unless answer_pings

            socket.write(WebSocket::Frame::Outgoing::Server.new(version: 13, data: frame.data, type: :pong).to_s)
          end
        end
      end
    rescue IOError, SystemCallError
      nil
    end
  end

  class FakeRobot
    attr_reader :received

    def initialize(handler_delay: 0)
      @received = Queue.new
      @handler_delay = handler_delay
    end

    def receive(attributes)
      sleep(@handler_delay)
      @received << attributes
    end

    def receive_events_api(_type, _data); end
  end

  class FakeWebClient
    def auth_test
      { 'ok' => true, 'user' => 'ruboty', 'user_id' => 'U00000SELF' }
    end

    def users_list
      { 'ok' => true, 'members' => [{ 'id' => 'U00000USER', 'name' => 'alice' }] }
    end

    def conversations_list
      { 'ok' => true, 'channels' => [] }
    end

    def get(_path)
      { 'ok' => true, 'usergroups' => [] }
    end
  end

  ENV_KEYS = %w[SLACK_APP_TOKEN SLACK_BOT_TOKEN SLACK_AUTO_RECONNECT RUBOTY_NAME].freeze

  setup do
    @original_env = ENV.to_h.slice(*ENV_KEYS)
    ENV['SLACK_APP_TOKEN'] = 'xapp-dummy'
    ENV['SLACK_BOT_TOKEN'] = 'xoxb-dummy'
    ENV['SLACK_AUTO_RECONNECT'] = '1'
    @original_logger = Ruboty.instance_variable_get(:@logger)
    @log = StringIO.new
    Ruboty.instance_variable_set(:@logger, Logger.new(@log))
    @server = FakeSlackServer.new
  end

  teardown do
    @run_thread&.kill
    @adapter&.instance_variable_get(:@event_worker)&.kill
    @server.stop
    ENV_KEYS.each { |key| ENV.delete(key) }
    ENV.update(@original_env)
    Ruboty.instance_variable_set(:@logger, @original_logger)
  end

  def start_adapter(robot: FakeRobot.new, url_failures: 0, idle_timeout: 0.5)
    @robot = robot
    @adapter = Ruboty::Adapters::SlackSocketMode.new(robot)
    @adapter.instance_variable_set(:@client, FakeWebClient.new)
    server = @server
    remaining_failures = url_failures
    @adapter.define_singleton_method(:url) do
      if remaining_failures > 0
        remaining_failures -= 1
        raise 'apps.connections.open failed: internal_error'
      end
      server.url
    end
    @adapter.define_singleton_method(:socket_options) do
      { ping_interval: 0.1, idle_timeout: idle_timeout, watchdog_interval: 0.05 }
    end
    @adapter.define_singleton_method(:reconnect_wait) { |_failures| 0.05 }
    @run_thread = Thread.new { @adapter.run }
  end

  def message_event(text, envelope_id)
    {
      'type' => 'events_api',
      'envelope_id' => envelope_id,
      'payload' => {
        'event' => {
          'type' => 'message', 'channel' => 'D0000000001', 'user' => 'U00000USER',
          'text' => text, 'ts' => '1700000000.000100'
        }
      }
    }
  end

  def assert_receives(conn, text, envelope_id)
    @server.send_event(conn, message_event(text, envelope_id))
    received = @robot.received.pop(timeout: 5)
    assert_not_nil received, "robot did not receive #{text}"
    assert_equal text, received[:body]
  end

  test 'reconnects after the server drops the connection' do
    # A long idle timeout makes sure the drop is noticed by the failing ping.
    start_adapter(idle_timeout: 30)
    first = @server.next_connection
    assert_receives(first, 'before', 'env-1')

    first.socket.close

    second = @server.next_connection
    assert_receives(second, 'after', 'env-2')
    assert_not_match(/nothing received/, @log.string)
  end

  test 'reconnects when the connection goes silent without an error' do
    start_adapter
    first = @server.next_connection
    @server.answer_pings = false

    second = @server.next_connection
    @server.answer_pings = true
    assert_receives(second, 'after', 'env-2')
    assert_match(/nothing received/, @log.string)
  ensure
    first&.socket&.close
  end

  test 'keeps retrying when opening a connection fails' do
    start_adapter(url_failures: 2)

    conn = @server.next_connection
    assert_receives(conn, 'after', 'env-1')
    assert_equal 2, @log.string.scan(/Socket Mode connection failed/).size
  end

  test 'acks events while a previous command is still running' do
    start_adapter(robot: FakeRobot.new(handler_delay: 2))
    conn = @server.next_connection

    @server.send_event(conn, message_event('slow', 'env-1'))
    @server.send_event(conn, message_event('next', 'env-2'))

    acks = 2.times.map { @server.acks.pop(timeout: 1) }
    assert_equal %w[env-1 env-2], acks.map { |ack| ack && ack['envelope_id'] }
    assert_true @robot.received.empty?, 'acks should not wait for the slow command'
    assert_equal %w[slow next], 2.times.map { @robot.received.pop(timeout: 10)[:body] }
  end
end
