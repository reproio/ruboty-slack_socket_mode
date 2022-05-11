require "ostruct"

module Ruboty
  module SlackSocketMode
    module Handlers
      class EventsApiAction
        attr_reader :event_type, :method_name

        def initialize(event_type, method_name)
          @event_type = event_type
          @method_name = method_name
        end
      end

      class EventsApiHandler
        class << self
          include Mem

          def inherited(child)
            Ruboty::SlackSocketMode::Handlers.events_api << child
          end

          def on_event(event_type:, name:)
            actions << EventsApiAction.new(event_type, name)
          end

          def actions
            []
          end
          memoize :actions
        end

        attr_reader :robot

        def initialize(robot)
          @robot = robot
        end
      end
    end
  end
end
