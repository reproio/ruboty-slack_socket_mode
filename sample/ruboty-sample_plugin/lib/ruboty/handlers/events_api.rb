module Ruboty::SlackSocketMode::Handlers
  class EventsApi < EventsApiHandler
    on(
      event_type: 'app_home_opened',
      name: 'app_home_opened'
    )

    def app_home_opened(message)
      pp 'app_home_opened!'
      pp message
    end
  end
end
