# frozen_string_literal: true

require 'http'
module CalendarCoordinator
  # Event Service
  class EventService
    def initialize(config)
      @config = config
    end

    # Save google events to Database
    def save_from_google(current_account:, calendar_gid:, google_events:)
      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .post("#{@config.API_URL}/google/calendar/#{calendar_gid}/events", json: google_events)
      raise('Save failed') unless response.code == 201
    end
  end
end
