require 'ruboty/message'

module Ruboty
  module SlackSocketMode
    module Message
      def add_reaction(reaction)
        channel_id = @original[:channel]["id"]
        timestamp  = @original[:time].to_f
        robot.add_reaction(reaction, channel_id, timestamp)
      end

      def user_id
        @original.dig(:user, "id")
      end

      def reply_as_ephemeral(body, options = {})
        reply(body, options.merge(ephemeral: true, user_id: user_id))
      end

      def delete
        robot.delete_ephemeral_message(@original[:data]["response_url"])
      end
    end
  end

  Message.include SlackSocketMode::Message
end
