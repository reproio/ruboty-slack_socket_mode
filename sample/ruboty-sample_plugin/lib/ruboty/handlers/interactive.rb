module Ruboty::SlackSocketMode::Handlers
  class Interactive < InteractiveHandler
    on_interactive(
      action_id: 'action_ephemeral_ok',
      name: 'ephemeral_ok'
    )

    def ephemeral_ok(message)
      message.delete
    end
  end
end
