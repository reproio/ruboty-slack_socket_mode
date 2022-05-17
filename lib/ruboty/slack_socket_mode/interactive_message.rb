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

      def from_name
        @payload.dig("user", "name")
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

      def reply_as_ephemeral(body, options = {})
        reply(body, options.merge(ephemeral: true, user_id: user_id))
      end

      def delete
        response_url = @payload['response_url']
        unless response_url
          Ruboty.logger.warn("#{self.class.name}: Cannot delete message. This message does not contain response_url in payload.")
          return
        end

        robot.delete_interactive(response_url)
      end

      def update(text: nil, block: nil)
        response_url = @payload['response_url']
        unless response_url
          Ruboty.logger.warn("#{self.class.name}: Cannot update message. This message does not contain response_url in payload.")
          return
        end

        if text.nil? && block.nil? || text && block
          Ruboty.logger.warn("#{self.class.name}: Cannot update message. Wrong number of arguments (expected text or block)")
          return
        end

        if text.is_a?(String)
          robot.update_interactive_message(response_url, text)
        elsif block.is_a?(Array)
          robot.update_interactive_block(response_url, block)
        else
          Ruboty.logger.warn("#{self.class.name}: Cannot update message. This is not match argument type.")
          return
        end
      end

      def selected_value(block_id, action_id)
        unless @payload.dig('state', 'values', block_id, action_id, 'selected_option', 'value')
          Ruboty.logger.warn("#{self.class.name}: Cannot get selected value. Block_id or action_id is not found")
          return
        end
        return @payload.dig('state', 'values', block_id, action_id, 'selected_option', 'value')
      end
    end
  end
end
