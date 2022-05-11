require 'ruboty/message'

module Ruboty
  module SlackSocketMode
    class InteractiveMessage
      attr_reader :action_id, :payload

      def initialize(robot, payload)
        @robot = robot
        @payload = payload
        @action_id = payload['actions'].first['action_id']
      end

      def delete
        unless @payload['response_url']
          Ruboty.logger.warn("#{self.class.name}: Cannot delete message. This is not an ephemeral message.")
          return
        end
        @robot.delete_ephemeral_message(@payload['response_url'])
      end

      private

      attr_reader :robot
    end
  end
end
