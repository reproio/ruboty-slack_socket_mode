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
      action_id: 'action_update_blocks',
      name: 'update_blocks'
    )
    on_interactive(
      action_id: 'action_more_message',
      name: 'more_message'
    )
    on_interactive(
      action_id: 'action_more_blocks',
      name: 'more_blocks'
    )
    on_interactive(
      action_id: 'action_more_ephemeral_message',
      name: 'more_ephemeral_message'
    )
    on_interactive(
      action_id: 'action_more_ephemeral_blocks',
      name: 'more_ephemeral_blocks'
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
      message.update_message("Update!")
    end

    def update_blocks(message)
      message.update_blocks(update_sample_blocks)
    end

    def more_message(message)
      message.reply("Hello, #{message.from_name}!")
    end

    def more_blocks(message)
      message.reply_blocks(reply_sample_blocks)
    end

    def more_ephemeral_message(message)
      message.reply_as_ephemeral("Hello, #{message.from_name}!")
    end

    def more_ephemeral_blocks(message)
      message.reply_blocks_as_ephemeral(reply_sample_blocks)
    end

    private
    def update_sample_blocks
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
    def reply_sample_blocks
      [
        {
          "type": "section",
          "text": { "type": "plain_text", "text": "More message! Push Delete button" }
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
