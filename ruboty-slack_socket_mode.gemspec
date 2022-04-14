# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruboty/slack_socket_mode/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruboty-slack_socket_mode'
  spec.version       = Ruboty::SlackSocketMode::VERSION
  spec.authors       = ['Repro Inc.']
  spec.email         = ['ryo.takaishi@repro.io']
  spec.summary       = 'Slack adapter with EventAPI + SocketMode for Ruboty'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/reproio/ruboty-slack_socket_mode'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop', '>= 0.28.0'

  spec.add_dependency 'ruboty', '>= 1.1.4'
  spec.add_dependency 'slack-ruby-client', '~> 1.0'
  spec.add_dependency 'faraday', '~> 1.0'
  spec.add_dependency 'websocket-client-simple', '>= 0.5.0'
end
