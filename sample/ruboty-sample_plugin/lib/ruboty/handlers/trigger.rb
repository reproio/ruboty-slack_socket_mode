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
        message.reply('This is interactive message', blocks: interactive_blocks)
      end

      def reply_interactive_as_ephemeral(message)
        message.reply_as_ephemeral('This is ephemeral interactive message', blocks: interactive_blocks)
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
                "text": { "type": "plain_text", "text": "More message" },
                "action_id": "action_more"
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
end
