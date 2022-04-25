require "ruboty/sample_plugin/version"

module Ruboty
  module Handlers
    class Interactive < Base
      on(
        /slack_interactive\:\:(?<action>.*)\z/,
        name: 'slack_interactive',
        description: 'Slack Interactive callback'
      )

      def slack_interactive(message)
        action = message.match_data[:action]
        interactive(action, message)
      end

      def interactive(action, message)
        if action == 'action_ephemeral_ok'
          message.delete
        end
      end
    end
  end
end
