require 'ruboty/slack_socket_mode/interactive_command'

module Ruboty
  module SlackSocketMode
    module Handlers

      class InteractiveHandler
        class << self
          attr_reader :commands

          def inherited(child)
            Ruboty::SlackSocketMode::Handlers.interactive << child
          end

          def on_interactive(action_id:, name:)
            @commands ||= []
            @commands << Ruboty::SlackSocketMode::InteractiveCommand.new(action_id, name)
          end
        end

        attr_reader :robot

        def initialize(robot)
          @robot = robot
        end
      end
    end
  end
end
