# Ruboty::SlackSocketMode

Slack(Socket Mode) adapter for [ruboty](https://github.com/r7kamura/ruboty).
This gem is experimental.

This is fork of [rosylilly/ruboty-slack_rtm](https://github.com/rosylilly/ruboty-slack_rtm),
adapted new slack API(Socket Mode) instead of old API(RTM).

## Development

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

For instant confirmation, `sample` directory may be useful with below steps.
You will need a slack workspace and slack app tokens. you can use `sample/slack_app_manifest.yml` to create a slack app.

```sh
cd sample
cp .env.sample .env # and fill your slack_app tokens

docker compose run --rm ruboty
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/reproio/ruboty-slack_socket_mode.
