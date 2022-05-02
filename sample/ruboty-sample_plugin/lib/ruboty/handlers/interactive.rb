module Ruboty::SlackSocketMode::Handlers
  class Interactive < InteractiveHandler
    on(
      action_id: 'action_ephemeral_ok',
      name: 'slack_interactive'
    )

    def interactive(action, message)
      if action == 'action_ephemeral_ok'
        message.delete
      end
    end
  end
end
