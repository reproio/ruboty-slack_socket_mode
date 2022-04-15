require "ruboty/sample_plugin/version"

module Ruboty
  module Handlers
    class SamplePlugin < Base
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
    end
  end
end
