module Ruboty::SlackSocketMode::Handlers
  class Interactive < InteractiveHandler
    on_interactive(
      action_id: 'action_select',
      name: 'select'
    )
    on_interactive(
      action_id: 'action_delete',
      name: 'delete'
    )
    on_interactive(
      action_id: 'action_more',
      name: 'more'
    )
    on_interactive(
      action_id: 'action_update_message',
      name: 'update_message'
    )
    on_interactive(
      action_id: 'action_update_block',
      name: 'update_block'
    )
    on_interactive(
      action_id: 'action_more_ephemeral',
      name: 'more_ephemeral'
    )

    def select(message)
      message.reply(message.selected_value("select","action_select"))
    end

    def delete(message)
      message.delete
    end

    def more(message)
      message.reply("Hello, #{message.from_name}!")
    end

    def update_message(message)
      message.update(text: "Update!")
    end

    def update_block(message)
      message.update(block: interactive_blocks)
    end

    def more_ephemeral(message)
      message.reply_as_ephemeral("Hello, #{message.from_name}!")
    end

    private
    def interactive_blocks
      [
        {
          "type": "section",
          "text": { "type": "plain_text", "text": "Update! Push Delete button" }
        },
        {
          "type": "actions",
          "elements": [
            {
              "type": "button",
              "text": { "type": "plain_text", "text": "Delete" },
              "action_id": "action_delete"
            }
          ]
        }
      ]
    end
  end
end
