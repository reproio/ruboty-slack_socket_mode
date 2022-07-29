require 'ruboty/slack_socket_mode/events_api_command'

module Ruboty
  module SlackSocketMode
    module Handlers
      class EventsApiHandler
        class << self
          attr_reader :commands

          def inherited(child)
            Ruboty::SlackSocketMode::Handlers.events_api << child
          end

          def on_event(event_type:, name:)
            @commands ||= []
            @commands << Ruboty::SlackSocketMode::EventsApiCommand.new(event_type, name)
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
