require "ostruct"

module Ruboty
  module SlackSocketMode
    module Handlers
      class InteractiveAction
        attr_reader :action_id, :method_name

        def initialize(action_id, method_name)
          @action_id = action_id
          @method_name = method_name
        end
      end

      class InteractiveHandler
        class << self
          include Mem

          def inherited(child)
            Ruboty::SlackSocketMode::Handlers.interactive << child
          end

          def on_interactive(action_id:, name:)
            actions << InteractiveAction.new(action_id, name)
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
