require 'ruboty'

module Ruboty
  module SlackSocketMode
    module Handlers
      @events_api = []
      @interactive = []

      class << self
        attr_reader :events_api, :interactive
      end
    end
  end
end
