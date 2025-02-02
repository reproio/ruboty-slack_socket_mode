require 'ruboty/message'

module Ruboty
  module SlackSocketMode
    class InteractiveMessage
      attr_reader :robot, :action_id, :payload

      def initialize(robot, payload)
        @robot = robot
        @payload = payload
        @action_id = payload.dig('actions', 0, 'action_id')
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

      def reply_blocks(blocks, options = {})
        reply("", options.merge(blocks: blocks))
      end

      def reply_as_ephemeral(body, options = {})
        reply(body, options.merge(ephemeral: true, user_id: user_id))
      end

      def reply_blocks_as_ephemeral(blocks, options = {})
        reply("", options.merge(blocks: blocks, ephemeral: true, user_id: user_id))
      end

      def delete
        response_url = @payload['response_url']
        unless response_url
          Ruboty.logger.warn("#{self.class.name}: Cannot delete message. This message does not contain response_url in payload.")
          return
        end

        robot.delete_interactive(response_url)
      end

      def update(text)
        response_url = @payload['response_url']
        unless response_url
          Ruboty.logger.warn("#{self.class.name}: Cannot update message. This message does not contain response_url in payload.")
          return
        end

        robot.update_interactive(response_url, text, nil)
      end

      def update_blocks(blocks)
        response_url = @payload['response_url']
        unless response_url
          Ruboty.logger.warn("#{self.class.name}: Cannot update blocks. This blocks does not contain response_url in payload.")
          return
        end

        robot.update_interactive(response_url, nil, blocks)
      end

      def state(block_id:, action_id:)
        block = @payload.dig('state', 'values', block_id)
        unless block
          Ruboty.logger.warn("#{self.class.name}: Cannot get state. block_id: #{block_id} is not found")
          return
        end

        state = block[action_id]
        unless state
          Ruboty.logger.warn("#{self.class.name}: Cannot get state. action_id: #{action_id} is not found")
          return
        end

        case state['type']
        when 'static_select' then state.dig('selected_option', 'value')
        when 'multi_static_select' then state.dig('selected_options').map { |selected_option| selected_option['value'] }
        when 'multi_conversations_select' then state.dig('selected_conversations')
        when 'checkboxes' then state.dig('selected_options').map { |selected_option| selected_option['value'] }
        when 'radio_buttons' then state.dig('selected_option', 'value')
        when 'timepicker' then state.dig('selected_time')
        when 'users_select' then state.dig('selected_user')
        when 'multi_users_select' then state.dig('selected_users')
        when 'datepicker' then state.dig('selected_date')
        when 'plain_text_input' then state.dig('value')
        else
          Ruboty.logger.warn("#{self.class.name}: Cannot get state. This is unsupported type: #{state['type']}.")
          nil
        end
      end
    end
  end
end
