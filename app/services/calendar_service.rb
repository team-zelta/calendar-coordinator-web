# frozen_string_literal: true

require 'http'
require 'json'
require 'date'

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

      raise('Save failed') unless response.code == 201

      JSON.parse(response.body)
    end

    # Get Common Busy Time
    def list_common_busy_time(group_id:, calendar_mode:, date:)
      datetime = "#{DateTime.parse(date).year}-#{DateTime.parse(date).month}-#{DateTime.parse(date).day}"

      response = HTTP.get("#{@config.API_URL}/groups/#{group_id}/common-busy-time/#{calendar_mode}/#{datetime}")
      raise('Get Common Busy Time failed') unless response.code == 200

      JSON.parse(response.body, object_class: OpenStruct)
    end

    # Get all events
    def list_events(group_id:, calendar_mode:, date:)
      datetime = "#{DateTime.parse(date).year}-#{DateTime.parse(date).month}-#{DateTime.parse(date).day}"

      response = HTTP.get("#{@config.API_URL}/groups/#{group_id}/events/#{calendar_mode}/#{datetime}")
      raise('Get All Events failed') unless response.code == 200

      JSON.parse(response.body, object_class: OpenStruct)
    end
  end
end
