module Ruboty
  module SlackSocketMode
    class EventsApiCommand
      attr_reader :event_type, :method_name

      def initialize(event_type, method_name)
        @event_type = event_type
        @method_name = method_name
      end
    end
  end
end
