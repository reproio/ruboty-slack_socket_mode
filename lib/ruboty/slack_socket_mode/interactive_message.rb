require 'ruboty/message'

module Ruboty
  module SlackSocketMode
    class InteractiveMessage
      attr_reader :robot, :action_id, :payload

      def initialize(robot, payload)
        @robot = robot
        @payload = payload
        @action_id = payload['actions'].first['action_id']
      end

      def from
        @payload.dig("channel", "id")
      end

      def user_id
        @payload.dig("user", "id")
      end

      def reply(body, options = {})
        unless from
          Ruboty.logger.warn("#{self.class.name}: Cannot reply message. Destination channel is not found.")
          return
        end

        attributes = { body: body, to: from, original: @payload }.merge(options)
        robot.say(attributes)
      end

      def reply_ephemeral(body, options = {})
        reply(body, options.merge(ephemeral: true, user_id: user_id))
      end

      def delete
        unless @payload['response_url']
          Ruboty.logger.warn("#{self.class.name}: Cannot delete message. This is not an ephemeral message.")
          return
        end
        @robot.delete_ephemeral_message(@payload['response_url'])
      end
    end
  end
end
