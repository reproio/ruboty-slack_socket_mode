require 'test_helper'

class TestSlackSocketMode < Test::Unit::TestCase
  SELF_USER_ID = 'U00000SELF'
  SELF_BOT_ID = 'B00000SELF'
  OTHER_USER_ID = 'U0000OTHER'
  OTHER_BOT_USER_ID = 'U00OTHERBOT'
  OTHER_BOT_ID = 'B00OTHERBOT'
  WEBHOOK_BOT_ID = 'B000WEBHOOK'

  BASE_MESSAGE = { 'type' => 'message', 'channel' => 'D0000000001', 'text' => 'ruboty ping', 'ts' => '1700000000.000100' }

  class FakeRobot
    attr_reader :received

    def initialize
      @received = []
    end

    def receive(attributes)
      @received << attributes
    end
  end

  class FakeClient
    def auth_test
      { 'ok' => true, 'user' => 'ruboty', 'user_id' => SELF_USER_ID, 'bot_id' => SELF_BOT_ID }
    end

    def users_list
      {
        'ok' => true,
        'members' => [
          { 'id' => SELF_USER_ID, 'name' => 'ruboty', 'is_bot' => true },
          { 'id' => OTHER_USER_ID, 'name' => 'alice', 'is_bot' => false },
          { 'id' => OTHER_BOT_USER_ID, 'name' => 'other-bot', 'is_bot' => true }
        ]
      }
    end

    def conversations_list
      { 'ok' => true, 'channels' => [] }
    end

    def get(_path)
      { 'ok' => true, 'usergroups' => [] }
    end
  end

  ENV_KEYS = %w[
    SLACK_APP_TOKEN
    SLACK_BOT_TOKEN
    SLACK_EXPOSE_CHANNEL_NAME
    SLACK_IGNORE_GENERAL
    SLACK_GENERAL_NAME
    SLACK_IGNORE_BOT_MESSAGE
    SLACK_IGNORE_SELF_MESSAGE
    SLACK_IGNORE_WEBHOOK_MESSAGE
    RUBOTY_NAME
  ]

  setup do
    @original_env = ENV.to_h.slice(*ENV_KEYS)
    ENV_KEYS.each { |key| ENV.delete(key) }
    ENV['SLACK_APP_TOKEN'] = 'xapp-dummy'
    ENV['SLACK_BOT_TOKEN'] = 'xoxb-dummy'

    @original_logger = Ruboty.instance_variable_get(:@logger)
    @log = StringIO.new
    Ruboty.instance_variable_set(:@logger, Logger.new(@log))

    @robot = FakeRobot.new
    @adapter = Ruboty::Adapters::SlackSocketMode.new(@robot)
    @adapter.instance_variable_set(:@client, FakeClient.new)
    @adapter.send(:init)
  end

  teardown do
    ENV_KEYS.each { |key| ENV.delete(key) }
    ENV.update(@original_env)
    Ruboty.instance_variable_set(:@logger, @original_logger)
  end

  def message_from_self
    BASE_MESSAGE.merge('user' => SELF_USER_ID, 'bot_id' => SELF_BOT_ID)
  end

  def message_from_own_app_webhook
    BASE_MESSAGE.merge('subtype' => 'bot_message', 'bot_id' => SELF_BOT_ID)
  end

  def message_from_webhook
    BASE_MESSAGE.merge('subtype' => 'bot_message', 'bot_id' => WEBHOOK_BOT_ID)
  end

  def message_from_other_user
    BASE_MESSAGE.merge('user' => OTHER_USER_ID)
  end

  def message_from_other_bot
    BASE_MESSAGE.merge('user' => OTHER_BOT_USER_ID, 'bot_id' => OTHER_BOT_ID)
  end

  def received_messages_for(data)
    @adapter.send(:on_message, data)
    @robot.received
  end

  sub_test_case 'without ignore settings' do
    test 'receives messages from itself' do
      assert_equal 1, received_messages_for(message_from_self).size
    end

    test 'receives messages from incoming webhooks' do
      assert_equal 1, received_messages_for(message_from_webhook).size
    end

    test 'does not log anything about ignoring' do
      received_messages_for(message_from_self)
      received_messages_for(message_from_webhook)
      assert_not_include @log.string, 'Ignored'
    end
  end

  sub_test_case 'SLACK_IGNORE_SELF_MESSAGE=1' do
    setup do
      ENV['SLACK_IGNORE_SELF_MESSAGE'] = '1'
    end

    test 'ignores messages posted by its own user' do
      assert_empty received_messages_for(message_from_self)
    end

    test 'logs ignored messages at info level' do
      received_messages_for(message_from_self)
      assert_include @log.string, 'INFO'
      assert_include @log.string, 'Ignored a message posted by itself'
      assert_include @log.string, "channel=#{BASE_MESSAGE['channel']} ts=#{BASE_MESSAGE['ts']}"
    end

    test 'receives messages from other users' do
      assert_equal 1, received_messages_for(message_from_other_user).size
    end

    test 'receives messages from incoming webhooks' do
      assert_equal 1, received_messages_for(message_from_webhook).size
    end

    test 'receives messages from incoming webhooks of its own app' do
      assert_equal 1, received_messages_for(message_from_own_app_webhook).size
    end
  end

  sub_test_case 'SLACK_IGNORE_WEBHOOK_MESSAGE=1' do
    setup do
      ENV['SLACK_IGNORE_WEBHOOK_MESSAGE'] = '1'
    end

    test 'ignores messages from incoming webhooks' do
      assert_empty received_messages_for(message_from_webhook)
    end

    test 'logs ignored messages at info level' do
      received_messages_for(message_from_webhook)
      assert_include @log.string, 'INFO'
      assert_include @log.string, 'Ignored a message posted without a user'
      assert_include @log.string, "subtype=bot_message bot_id=#{WEBHOOK_BOT_ID}"
    end

    test 'ignores messages from incoming webhooks of its own app' do
      assert_empty received_messages_for(message_from_own_app_webhook)
    end

    test 'receives messages from other users' do
      assert_equal 1, received_messages_for(message_from_other_user).size
    end

    test 'receives messages from itself' do
      assert_equal 1, received_messages_for(message_from_self).size
    end

    test 'receives messages from other apps posted with a bot user' do
      assert_equal 1, received_messages_for(message_from_other_bot).size
    end
  end

  sub_test_case 'SLACK_IGNORE_SELF_MESSAGE=1 and SLACK_IGNORE_WEBHOOK_MESSAGE=1' do
    setup do
      ENV['SLACK_IGNORE_SELF_MESSAGE'] = '1'
      ENV['SLACK_IGNORE_WEBHOOK_MESSAGE'] = '1'
    end

    test 'ignores messages from itself' do
      assert_empty received_messages_for(message_from_self)
    end

    test 'ignores messages from incoming webhooks' do
      assert_empty received_messages_for(message_from_webhook)
    end

    test 'receives messages from other apps posted with a bot user' do
      assert_equal 1, received_messages_for(message_from_other_bot).size
    end
  end
end
