require 'ruboty/robot'

module Ruboty
  module SlackSocketMode
    module Robot
      include Mem
      delegate :add_reaction, to: :adapter

      def add_reaction(reaction, channel_id, timestamp)
        adapter.add_reaction(reaction, channel_id, timestamp)
        true
      end

      def delete_ephemeral_message(response_url)
        adapter.delete_ephemeral_message(response_url)
      end

      def receive_events_api(event_type, data)
        events_api_handlers.each do |handler|
          handler.class.actions.each do |action|
            handler.send(action.method_name, data) if action.event_type == event_type
          end
        end
      end

      def receive_interactive(action_id, data)
        interactive_handlers.each do |handler|
          handler.class.actions.each do |action|
            handler.send(action.method_name, data) if action.action_id == action_id
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
