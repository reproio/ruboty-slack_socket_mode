require 'ruboty/robot'

module Ruboty
  module SlackSocketMode
    module Robot
      include Mem
      delegate :add_reaction, to: :adapter
      delegate :delete_interactive, to: :adapter

      def add_reaction(reaction, channel_id, timestamp)
        adapter.add_reaction(reaction, channel_id, timestamp)
        true
      end

      def receive_events_api(event_type, data)
        events_api_handlers.each do |handler|
          handler.class.commands.each do |command|
            handler.send(command.method_name, data) if command.event_type == event_type
          end
        end
      end

      def receive_interactive(interactive_message)
        interactive_handlers.each do |handler|
          handler.class.commands.each do |command|
            handler.send(command.method_name, interactive_message) if command.action_id == interactive_message.action_id
          end
        end
      end

      private

      def events_api_handlers
        Handlers.events_api.map { |handler_class| handler_class.new(self) }
      end
      memoize :events_api_handlers

      def interactive_handlers
        Handlers.interactive.map { |handler_class| handler_class.new(self) }
      end
      memoize :interactive_handlers
    end
  end

  Robot.include SlackSocketMode::Robot
end
