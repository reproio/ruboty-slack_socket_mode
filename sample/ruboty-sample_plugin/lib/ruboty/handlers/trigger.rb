require "ruboty/sample_plugin/version"

module Ruboty
  module Handlers
    class Trigger < Base
      on(
        /attachment\z/i,
        name: 'reply_with_attachments',
        description: 'reply with attachments',
      )
      on(
        /file\z/i,
        name: 'reply_with_file_attachment',
        description: 'reply with a file attachment',
      )
      on(
        /interactive\z/i,
        name: 'reply_interactive',
        description: 'reply an interactive message',
      )
      on(
        /interactive_ephemeral\z/i,
        name: 'reply_interactive_as_ephemeral',
        description: 'reply an interactive message as ephemeral',
      )
      on(
        /interactive_form\z/i,
        name: 'reply_interactive_form',
        description: 'reply an interactive message',
      )

      def reply_with_attachments(message)
        message.reply('', attachments: [{
          "text": "This is an attachment",
          "id": 1,
          "fallback": "This is an attachment's fallback"
        }])
      end

      def reply_with_file_attachment(message)
        message.reply('', file: {
            path: 'sample_file',
            title: 'sample_file',
            content_type: 'text/plain'
          }
        )
      end

      def reply_interactive(message)
        message.reply_blocks(interactive_blocks)
      end

      def reply_interactive_as_ephemeral(message)
        message.reply_blocks_as_ephemeral(interactive_blocks)
      end

      def reply_interactive_form(message)
        message.reply_blocks(interactive_form)
      end

      private

      def interactive_blocks
        [
          {
            "type": "section",
            "text": { "type": "plain_text", "text": "Push any buttons" }
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
                "text": { "type": "plain_text", "text": "Update message" },
                "action_id": "action_update"
              },
              {
                "type": "button",
                "text": { "type": "plain_text", "text": "Update blocks" },
                "action_id": "action_update_blocks"
              },
              {
                "type": "button",
                "text": { "type": "plain_text", "text": "More message" },
                "action_id": "action_more_message"
              },
              {
                "type": "button",
                "text": { "type": "plain_text", "text": "More blocks" },
                "action_id": "action_more_blocks"
              },
              {
                "type": "button",
                "text": { "type": "plain_text", "text": "More message (ephemeral)" },
                "action_id": "action_more_ephemeral_message"
              },
              {
                "type": "button",
                "text": { "type": "plain_text", "text": "More blocks (ephemeral)" },
                "action_id": "action_more_ephemeral_blocks"
              }
            ]
          }
        ]
      end

      def interactive_form
        [
          {
            "type": "section",
            "block_id": "static_select",
            "text": {
              "type": "mrkdwn",
              "text": "Pick an item from the dropdown list"
            },
            "accessory": {
              "type": "static_select",
              "placeholder": {
                "type": "plain_text",
                "text": "Select an item",
                "emoji": true
              },
              "options": [
                {
                  "text": {
                    "type": "plain_text",
                    "text": "value-0",
                    "emoji": true
                  },
                  "value": "value-0"
                },
                {
                  "text": {
                    "type": "plain_text",
                    "text": "value-1",
                    "emoji": true
                  },
                  "value": "value-1"
                },
                {
                  "text": {
                    "type": "plain_text",
                    "text": "value-2",
                    "emoji": true
                  },
                  "value": "value-2"
                }
              ],
              "action_id": "static_select-action"
            }
          },
          {
            "type": "section",
            "block_id": "multi_static_select",
            "text": {
              "type": "mrkdwn",
              "text": "Test block with multi static select"
            },
            "accessory": {
              "type": "multi_static_select",
              "placeholder": {
                "type": "plain_text",
                "text": "Select options",
                "emoji": true
              },
              "options": [
                {
                  "text": {
                    "type": "plain_text",
                    "text": "value-0",
                    "emoji": true
                  },
                  "value": "value-0"
                },
                {
                  "text": {
                    "type": "plain_text",
                    "text": "value-1",
                    "emoji": true
                  },
                  "value": "value-1"
                },
                {
                  "text": {
                    "type": "plain_text",
                    "text": "value-2",
                    "emoji": true
                  },
                  "value": "value-2"
                }
              ],
              "action_id": "multi_static_select-action"
            }
          },
          {
            "type": "section",
            "block_id": "multi_conversations_select",
            "text": {
              "type": "mrkdwn",
              "text": "Test block with multi conversations select"
            },
            "accessory": {
              "type": "multi_conversations_select",
              "placeholder": {
                "type": "plain_text",
                "text": "Select conversations",
                "emoji": true
              },
              "action_id": "multi_conversations_select-action"
            }
          },
          {
            "type": "section",
            "block_id": "datepicker",
            "text": {
              "type": "mrkdwn",
              "text": "Pick a date for the deadline."
            },
            "accessory": {
              "type": "datepicker",
              "initial_date": "1990-04-28",
              "placeholder": {
                "type": "plain_text",
                "text": "Select a date",
                "emoji": true
              },
              "action_id": "datepicker-action"
            }
          },
          {
            "type": "section",
            "block_id": "checkboxes",
            "text": {
              "type": "mrkdwn",
              "text": "This is a section block with checkboxes."
            },
            "accessory": {
              "type": "checkboxes",
              "options": [
                {
                  "text": {
                    "type": "mrkdwn",
                    "text": "value-0"
                  },
                  "description": {
                    "type": "mrkdwn",
                    "text": "discription"
                  },
                  "value": "value-0"
                },
                {
                  "text": {
                    "type": "mrkdwn",
                    "text": "value-1"
                  },
                  "description": {
                    "type": "mrkdwn",
                    "text": "discription"
                  },
                  "value": "value-1"
                },
                {
                  "text": {
                    "type": "mrkdwn",
                    "text": "value-2"
                  },
                  "description": {
                    "type": "mrkdwn",
                    "text": "description"
                  },
                  "value": "value-2"
                }
              ],
              "action_id": "checkboxes-action"
            }
          },
          {
            "type": "section",
            "block_id": "radio_buttons",
            "text": {
              "type": "mrkdwn",
              "text": "Section block with radio buttons"
            },
            "accessory": {
              "type": "radio_buttons",
              "options": [
                {
                  "text": {
                    "type": "plain_text",
                    "text": "value-0",
                    "emoji": true
                  },
                  "value": "value-0"
                },
                {
                  "text": {
                    "type": "plain_text",
                    "text": "value-1",
                    "emoji": true
                  },
                  "value": "value-1"
                },
                {
                  "text": {
                    "type": "plain_text",
                    "text": "value-2",
                    "emoji": true
                  },
                  "value": "value-2"
                }
              ],
              "action_id": "radio_buttons-action"
            }
          },
          {
            "type": "section",
            "block_id": "timepicker",
            "text": {
              "type": "mrkdwn",
              "text": "Section block with a timepicker"
            },
            "accessory": {
              "type": "timepicker",
              "initial_time": "13:37",
              "placeholder": {
                "type": "plain_text",
                "text": "Select time",
                "emoji": true
              },
              "action_id": "timepicker-action"
            }
          },
          {
            "type": "section",
            "block_id": "users_select",
            "text": {
              "type": "mrkdwn",
              "text": "Test block with users select"
            },
            "accessory": {
              "type": "users_select",
              "placeholder": {
                "type": "plain_text",
                "text": "Select a user",
                "emoji": true
              },
              "action_id": "users_select-action"
            }
          },
          {
            "type": "input",
            "block_id": "multi_users_select",
            "element": {
              "type": "multi_users_select",
              "placeholder": {
                "type": "plain_text",
                "text": "Select users",
                "emoji": true
              },
              "action_id": "multi_users_select-action"
            },
            "label": {
              "type": "plain_text",
              "text": "Label",
              "emoji": true
            }
          },
          {
            "type": "input",
            "block_id": "plain_text_input",
            "element": {
              "type": "plain_text_input",
              "action_id": "plain_text_input-action"
            },
            "label": {
              "type": "plain_text",
              "text": "Label",
              "emoji": true
            }
          },
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "This is a section block with a button."
            },
            "accessory": {
              "type": "button",
              "text": {
                "type": "plain_text",
                "text": "get_form",
                "emoji": true
              },
              "value": "get_form",
              "action_id": "action_get_form"
            }
          }
        ]
      end
    end
  end
end
