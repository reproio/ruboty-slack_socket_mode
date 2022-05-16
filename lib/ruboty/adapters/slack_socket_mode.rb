require 'cgi'
require 'time'
require 'json'
require 'slack'
require 'faraday'

require 'ruboty/adapters/base'
require 'ruboty/slack_socket_mode/interactive_message'

module Ruboty
  module Adapters
    class SlackSocketMode < Base
      env :SLACK_APP_TOKEN, "Slack App-Level token for Socket Mode."
      env :SLACK_BOT_TOKEN, "Slack OAuth token for using Web API."
      env :SLACK_EXPOSE_CHANNEL_NAME, "if this set to 1, message.to will be channel name instead of id", optional: true
      env :SLACK_IGNORE_BOT_MESSAGE, "If this set to 1, bot ignores bot_messages", optional: true
      env :SLACK_IGNORE_GENERAL, "if this set to 1, bot ignores all messages on #general channel", optional: true
      env :SLACK_GENERAL_NAME, "Set general channel name if your Slack changes general name", optional: true
      env :SLACK_AUTO_RECONNECT, "Enable auto reconnect", optional: true

      def run
        init
        bind
        connect
      end

      def say(message)
        channel = message[:to]
        args = {
          as_user: true,
          channel: channel
        }
        if message[:thread_ts] || (message[:original] && message[:original][:thread_ts])
          args.merge!(thread_ts: message[:thread_ts] || message[:original][:thread_ts])
        end

        if message[:file]
          path = message[:file][:path]
          args.merge!(
            channels: channel,
            file: Faraday::UploadIO.new(path, message[:file][:content_type]),
            title: message[:file][:title] || path,
            filename: File.basename(path),
            initial_comment: message[:body] || ''
          )
          client.files_upload(args)
          return
        end

        if message[:attachments] && !message[:attachments].empty?
          args.merge!(
            text: message[:code] ? "```\n#{message[:body]}\n```" : message[:body],
            parse: message[:parse] || 'full',
            unfurl_links: true,
            attachments: message[:attachments].to_json
          )
        elsif message[:blocks] && !message[:blocks].empty?
          args.merge!(
            blocks: message[:blocks],
          )
        else
          args.merge!(
            text: message[:code] ? "```\n#{message[:body]}\n```" : resolve_send_mention(message[:body]),
            mrkdwn: true
          )
        end

        if message[:ephemeral]
          args.merge!(user: message[:user_id])
          client.chat_postEphemeral(args)
        else
          client.chat_postMessage(args)
        end
      end

      def add_reaction(reaction, channel_id, timestamp)
        client.reactions_add(name: reaction, channel: channel_id, timestamp: timestamp)
      end

      def delete_interactive(response_url)
        params = { delete_original: "true" }
        post_as_json(response_url, params)
      end

      def update_interactive_block(response_url, block)
        params = {
          replace_original: "true",
          blocks: block,
        }
        post_as_json(response_url, params)
      end

      def update_interactive_message(response_url, text)
        params = {
          replace_original: "true",
          text: text,
        }
        post_as_json(response_url, params)
      end

      private

      def post_as_json(url, params)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme === "https"
        headers = { "Content-Type" => "application/json" }
        http.post(uri.path, params.to_json, headers)
      end

      def init
        response = client.auth_test
        @user_info_caches = {}
        @channel_info_caches = {}
        @usergroup_info_caches = {}

        ENV['RUBOTY_NAME'] ||= response['user']

        make_users_cache
        make_channels_cache
        make_usergroups_cache
      end

      def bind
        socket.on_text do |data|
          # We could not find whole event types in official document.
          # This cases will cover all event types found in official sample data.
          # ref: https://api.slack.com/apis/connections/socket-implement#events
          case data['type']
          when 'hello'
            Ruboty.logger.info("#{self.class.name}: Socket Mode connection is established.")
          when 'disconnect'
            # Nothing to do
            # auto reconnecting works if SLACK_AUTO_RECONNECT configured.
          when 'events_api'
            event = data.dig('payload', 'event')
            handle_events_api(event)

            method_name = :"on_#{event['type']}"
            send(method_name, event) if respond_to?(method_name, true)
          when 'slash_commands'
            # TODO: add event handling for Slash commands
          when 'interactive'
            handle_interactive(data['payload'])
          else
            Ruboty.logger.warn("#{self.class.name}: Received unsupported data type: '#{data['type']}'.")
          end
        end
      end

      def handle_events_api(data)
        robot.receive_events_api(data['type'], data)
      end

      def handle_interactive(data)
        interactive_message = Ruboty::SlackSocketMode::InteractiveMessage.new(robot, data)
        robot.receive_interactive(interactive_message)
      end

      def connect
        loop do
          socket.main_loop rescue nil
          break unless slack_auto_reconnect

          @url = nil
          @socket = nil
          bind
        end
      end

      def url
        @url ||= begin
          response = Net::HTTP.post(
            URI.parse('https://slack.com/api/apps.connections.open'), '',
            { 'Authorization' => "Bearer #{slack_app_token}" }
          )
          body = JSON.parse(response.body)
          raise response.body unless body['ok']

          URI.parse(body['url'])
        end
      end

      def client
        @client ||= ::Slack::Web::Client.new(token: slack_bot_token)
      end

      def socket
        @socket ||= ::Ruboty::SlackSocketMode::Client.new(websocket_url: url)
      end

      # event handlers
      def on_app_mention(data)
        user = user_info(data['user']) || {}

        channel = channel_info(data['channel'])

        return if (data['subtype'] == 'bot_message' || user['is_bot']) && slack_ignore_bot_message == '1'

        if channel
          return if channel['name'] == slack_general_name && slack_ignore_general == '1'

          channel_to = slack_expose_channel_name ? "##{channel['name']}" : channel['id']
        else # direct message
          channel_to = data['channel']
        end

        message_info = {
          from: data['channel'],
          from_name: user['name'],
          to: channel_to,
          channel: channel,
          user: user,
          ts: data['ts'],
          thread_ts: data['thread_ts'],
          time: Time.at(data['ts'].to_f)
        }

        text, mention_to = extract_mention(data['text'])
        robot.receive(message_info.merge(body: text, mention_to: mention_to))

        (data['attachments'] || []).each do |attachment|
          body, body_mention_to = extract_mention(attachment['fallback'] || "#{attachment['text']} #{attachment['pretext']}".strip)

          unless body.empty?
            robot.receive(message_info.merge(body: body, mention_to: body_mention_to))
          end
        end
      end
      # alias for app mentions in direct message (It comes with `type: "message"`)
      # ref: https://api.slack.com/events/app_mention
      alias_method :on_message, :on_app_mention

      def on_channel_change(data)
        make_channels_cache
      end
      alias_method :on_channel_deleted, :on_channel_change
      alias_method :on_channel_renamed, :on_channel_change
      alias_method :on_channel_archived, :on_channel_change
      alias_method :on_channel_unarchived, :on_channel_change

      def on_user_change(data)
        user = data['user'] || data['bot']
        @user_info_caches[user['id']] = user
      end
      alias_method :on_bot_added, :on_user_change
      alias_method :on_bot_changed, :on_user_change

      def extract_mention(text)
        mention_to = []

        text = (text || '').gsub(/\<\@(?<uid>[0-9A-Z]+)(?:\|(?<name>[^>]+))?\>/) do |_|
          name = Regexp.last_match[:name]

          unless name
            user = user_info(Regexp.last_match[:uid])

            mention_to << user

            name = user['name']
          end

          "@#{name}"
        end

        text.gsub!(/\<!subteam\^(?<usergroup_id>[0-9A-Z]+)(?:\|(?<handle>[^>]+))?\>/) do |_|
          handle = Regexp.last_match[:handle]

          unless handle
            handle = usergroup_info(Regexp.last_match[:usergroup_id])
          end

          "#{handle}"
        end

        text.gsub!(/\<!(?<special>[^>|@]+)(\|\@[^>]+)?\>/) do |_|
          "@#{Regexp.last_match[:special]}"
        end

        text.gsub!(/\<((?<link>[^>|]+)(?:\|(?<ref>[^>]*))?)\>/) do |_|
          Regexp.last_match[:ref] || Regexp.last_match[:link]
        end


        text.gsub!(/\#(?<room_id>[A-Z0-9]+)/) do |_|
          room_id = Regexp.last_match[:room_id]
          msg = "##{room_id}"

          if channel = channel_info(room_id)
            msg = "##{channel['name']}"
          end

          msg
        end

        [CGI.unescapeHTML(text), mention_to]
      end

      def resolve_send_mention(text)
        text = text.dup.to_s
        text.gsub!(/@(?<mention>[0-9a-z._-]+)/) do |_|
          mention = Regexp.last_match[:mention]
          msg = "@#{mention}"

          @user_info_caches.each_pair do |id, user|
            if user['name'].downcase == mention.downcase
              msg = "<@#{id}>"
            end
          end

          msg
        end

        text.gsub!(/@(?<special>(?:everyone|group|channel|here))/) do |_|
          "<!#{Regexp.last_match[:special]}>"
        end

        text.gsub!(/@(?<subteam_name>[0-9a-z._-]+)/) do |_|
          subteam_name = Regexp.last_match[:subteam_name]
          msg = "@#{subteam_name}"

          @usergroup_info_caches.each_pair do |id, usergroup|
            if usergroup && usergroup['handle'] == subteam_name
              msg = "<!subteam^#{usergroup['id']}>"
            end
          end
          msg
        end

        text.gsub!(/\#(?<room_id>[a-z0-9_-]+)/) do |_|
          room_id = Regexp.last_match[:room_id]
          msg = "##{room_id}"

          @channel_info_caches.each_pair do |id, channel|
            if channel && channel['name'] == room_id
              msg = "<##{id}|#{room_id}>"
            end
          end

          msg
        end

        text
      end

      def make_users_cache
        resp = client.users_list
        if resp['ok']
          resp['members'].each do |user|
            @user_info_caches[user['id']] = user
          end
        end
      end

      def make_channels_cache
        resp = client.conversations_list
        if resp['ok']
          resp['channels'].each do |channel|
            @channel_info_caches[channel['id']] = channel
          end
        end
      end

      def make_usergroups_cache
        resp = client.get("usergroups.list")
        if resp['ok']
          resp['usergroups'].each do |usergroup|
            @usergroup_info_caches[usergroup['id']] = usergroup
          end
        end
      end

      def user_info(user_id)
        return {} if user_id.to_s.empty?

        @user_info_caches[user_id] ||= begin
          resp = client.users_info(user: user_id)

          resp['user']
        end
      end

      def channel_info(channel_id)
        @channel_info_caches[channel_id] ||= begin
          resp = case channel_id
            when /^C/
              client.conversations_info(channel: channel_id)
            else
              {}
            end

          resp['channel']
        end
      end

      def resolve_channel_id(name)
        ret_id = nil
        @channel_info_caches.each_pair do |id, channel|
          if channel['name'] == name
            ret_id = id
            break
          end
        end
        return ret_id
      end

      def usergroup_info(usergroup_id)
        @usergroup_info_caches[usergroup_id] || begin
          make_usergroups_cache
          @usergroup_info_caches[usergroup_id]
        end
      end

      def slack_app_token
        ENV['SLACK_APP_TOKEN']
      end

      def slack_bot_token
        ENV['SLACK_BOT_TOKEN']
      end

      def slack_expose_channel_name
        ENV['SLACK_EXPOSE_CHANNEL_NAME'] == '1'
      end

      def slack_ignore_bot_message
        ENV['SLACK_IGNORE_BOT_MESSAGE']
      end

      def slack_ignore_general
        ENV['SLACK_IGNORE_GENERAL']
      end

      def slack_general_name
        ENV['SLACK_GENERAL_NAME'] || 'general'
      end

      def slack_auto_reconnect
        ENV['SLACK_AUTO_RECONNECT']
      end

      def ruboty_name
        ENV['RUBOTY_NAME']
      end
    end
  end
end
