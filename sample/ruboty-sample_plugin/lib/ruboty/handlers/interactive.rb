module Ruboty::SlackSocketMode::Handlers
  class Interactive < InteractiveHandler
    on_interactive(
      action_id: 'action_delete',
      name: 'delete'
    )
    on_interactive(
      action_id: 'action_more',
      name: 'more'
    )
    on_interactive(
      action_id: 'action_more_ephemeral',
      name: 'more_ephemeral'
    )

    def delete(message)
      message.delete
    end

    def more(message)
      message.reply("Hello, #{message.from_name}!")
    end

    def more_ephemeral(message)
      message.reply_as_ephemeral("Hello, #{message.from_name}!")
    end
  end
end
