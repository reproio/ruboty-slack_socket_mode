module Ruboty::SlackSocketMode::Handlers
  class Interactive < InteractiveHandler
    on_interactive(
      action_id: 'action_ephemeral_delete',
      name: 'delete'
    )
    on_interactive(
      action_id: 'action_ephemeral_more',
      name: 'more'
    )

    def delete(message)
      message.delete
    end

    def more(message)
      message.reply_ephemeral("Hello!")
    end
  end
end
