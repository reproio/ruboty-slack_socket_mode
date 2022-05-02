require "ostruct"

module Ruboty
  module SlackSocketMode
    module Handlers
      class InteractiveHandler
        class << self
          include Mem

          def inherited(child)
            Ruboty::SlackSocketMode::Handlers.interactive << child
          end

          def on(action_id:, name:)
            actions << OpenStruct.new(action_id: action_id, method_name: name)
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
