module Ruboty::SlackSocketMode::Handlers
  class Interactive < InteractiveHandler
    on_interactive(
      action_id: 'action_get_form',
      name: 'get_form'
    )
    on_interactive(
      action_id: 'action_delete',
      name: 'delete'
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
      action_id: 'action_more',
      name: 'more'
    )
    on_interactive(
      action_id: 'action_more_ephemeral',
      name: 'more_ephemeral'
    )
    def get_form(message)
      static_select = message.state(block_id: "static_select", action_id: "static_select-action")
      multi_static_select = message.state(block_id: "multi_static_select", action_id: "multi_static_select-action")
      multi_conversations_select = message.state(block_id: "multi_conversations_select", action_id: "multi_conversations_select-action")
      timepicker = message.state(block_id: "timepicker", action_id: "timepicker-action")
      datepicker = message.state(block_id: "datepicker", action_id: "datepicker-action")
      checkboxes = message.state(block_id: "checkboxes", action_id: "checkboxes-action")
      radio_buttons = message.state(block_id: "radio_buttons", action_id: "radio_buttons-action")
      users_select = message.state(block_id: "users_select", action_id: "users_select-action")
      multi_users_select = message.state(block_id: "multi_users_select", action_id: "multi_users_select-action")
      plain_text_input = message.state(block_id: "plain_text_input", action_id: "plain_text_input-action")

      text = <<~EOF
      static_select : #{static_select}
      multi_static_select : #{multi_static_select}
      multi_conversations_select : #{multi_conversations_select}
      timepicker : #{timepicker}
      datepicker : #{datepicker}
      checkboxes : #{checkboxes}
      radio_buttons : #{radio_buttons}
      users_select : #{users_select}
      multi_users_select : #{multi_users_select}
      plain_text_input : #{plain_text_input}
      EOF
      message.reply(text)
    end

    def delete(message)
      message.delete
    end

    def update_message(message)
      message.update(text: "Update!")
    end

    def update_block(message)
      message.update(blocks: interactive_blocks)
    end

    def more(message)
      message.reply("Hello, #{message.from_name}!")
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
