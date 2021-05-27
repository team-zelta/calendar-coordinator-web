# frozen_string_literal: true

require 'http'
require 'json'

module CalendarCoordinator
  # Calendar Service
  class CalendarService
    def initialize(config)
      @config = config
    end

    # Save Calendar to Database
    def save(account_id:, calendars:) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      calendar_lists = []
      calendars.each do |calendar|
        next unless calendar.access_role == 'owner'

        calendar_lists.push(
          {
            gid: calendar.id,
            summary: calendar.summary,
            description: calendar.description,
            location: calendar.location,
            time_zone: calendar.time_zone,
            access_role: calendar.access_role
          }
        )
      end

      puts "calendar_lists = #{calendar_lists}"

      response = HTTP.post("#{@config.API_URL}/accounts/#{account_id}/calendars", json: calendar_lists)

      raise('Register failed') unless response.code == 201

      JSON.parse(response.body)
    end
  end
end
