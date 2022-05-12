require "ruboty/sample_plugin/version"

module Ruboty
  module Handlers
    class Trigger < Base
      on(
        /attachment/i,
        name: 'reply_with_attachments',
        description: 'reply with attachments',
      )
      on(
        /file/i,
        name: 'reply_with_file_attachment',
        description: 'reply with a file attachment',
      )
      on(
        /ephemeral/i,
        name: 'reply_ephemeral',
        description: 'reply elphemeral message',
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

      def reply_ephemeral(message)
        message.reply_ephemeral(
          'this is ephemeral message',
          blocks: [
            {
              "type": "section",
              "text": { "type": "plain_text", "text": "This is ephemeral message" }
            },
            {
              "type": "actions",
              "elements": [
                {
                  "type": "button",
                  "text": { "type": "plain_text", "text": "Delete" },
                  "action_id": "action_ephemeral_delete"
                },
                {
                  "type": "button",
                  "text": { "type": "plain_text", "text": "More Message" },
                  "action_id": "action_ephemeral_more"
                }
              ]
            }
          ]
        )
      end
    end
  end
end
