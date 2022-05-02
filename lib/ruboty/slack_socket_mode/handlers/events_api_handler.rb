require "ostruct"

module Ruboty
  module SlackSocketMode
    module Handlers
      class EventsApiHandler
        class << self
          include Mem

          def inherited(child)
            Ruboty::SlackSocketMode::Handlers.events_api << child
          end

          def on(event_type:, name:)
            actions << OpenStruct.new(event_type: event_type, method_name: name)
          end

          def actions
            []
          end
          memoize :actions
        end

        include Env::Validatable

        attr_reader :robot

        def initialize(robot)
          @robot = robot
          validate!
        end
      end
    end
  end
end
