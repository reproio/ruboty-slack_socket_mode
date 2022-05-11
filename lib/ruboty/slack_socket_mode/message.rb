require 'ruboty/message'

module Ruboty
  module SlackSocketMode
    module Message
      def add_reaction(reaction)
        channel_id = @original[:channel]["id"]
        timestamp  = @original[:time].to_f
        robot.add_reaction(reaction, channel_id, timestamp)
      end
    end
  end

  Message.include SlackSocketMode::Message
end
