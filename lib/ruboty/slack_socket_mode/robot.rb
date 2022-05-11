require 'ruboty/robot'

module Ruboty
  module SlackSocketMode
    module Robot
      delegate :add_reaction, to: :adapter

      def add_reaction(reaction, channel_id, timestamp)
        adapter.add_reaction(reaction, channel_id, timestamp)
        true
      end
    end
  end

  Robot.include SlackSocketMode::Robot
end
