module Ruboty::SlackSocketMode::Handlers
  class EventsApi < EventsApiHandler
    on_event(
      event_type: 'app_home_opened',
      name: 'app_home_opened'
    )

    def app_home_opened(message)
      puts "App Home: #{message["tab"]} tab is opened!"
    end
  end
end
