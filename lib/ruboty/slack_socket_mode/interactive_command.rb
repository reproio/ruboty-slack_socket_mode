module Ruboty
  module SlackSocketMode
    class InteractiveCommand
      attr_reader :action_id, :method_name

      def initialize(action_id, method_name)
        @action_id = action_id
        @method_name = method_name
      end
    end
  end
end
