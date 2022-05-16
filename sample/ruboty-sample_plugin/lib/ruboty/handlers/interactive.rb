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
          "text": { "type": "plain_text", "text": "Push any buttons (updated)" }
        },
        {
          "type": "actions",
          "elements": [
            {
              "type": "button",
              "text": { "type": "plain_text", "text": "Delete" },
              "action_id": "action_delete"
            },
            {
              "type": "button",
              "text": { "type": "plain_text", "text": "More message" },
              "action_id": "action_more"
            },
            {
              "type": "button",
              "text": { "type": "plain_text", "text": "Update message" },
              "action_id": "action_update_messagee"
            },
            {
              "type": "button",
              "text": { "type": "plain_text", "text": "Update block" },
              "action_id": "action_update_block"
            },
            {
              "type": "button",
              "text": { "type": "plain_text", "text": "More message (ephemeral)" },
              "action_id": "action_more_ephemeral"
            }
          ]
        }
      ]
    end
  end
end
