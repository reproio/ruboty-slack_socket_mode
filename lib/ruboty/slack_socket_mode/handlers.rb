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
      end
    end
  end
end
