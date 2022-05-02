require 'ruboty'

module Ruboty
  module SlackSocketMode
    module Handlers
      class << self
        include Mem

        def events_api
          []
        end
        memoize :events_api

        def interactive
          []
        end
        memoize :interactive

        def slash_commands
          []
        end
        memoize :slash_commands
      end
    end
  end
end
