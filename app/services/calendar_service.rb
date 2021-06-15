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

    # Get all calendars of the current user
    def list_calendar(current_account, credentials)
      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .post("#{@config.API_URL}/google/calendar", json: { client_id: credentials.client_id,
                                                                         client_secret: credentials.client_secret,
                                                                         scope: credentials.scope,
                                                                         access_token: credentials.access_token,
                                                                         refresh_token: credentials.refresh_token,
                                                                         expires_at: credentials.expires_at,
                                                                         grant_type: credentials.grant_type })

      response.code == 200 ? JSON.parse(response, object_class: OpenStruct) : nil
    end

    # Get all calendars of the current user
    def list_calendars(current_account)
      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .get("#{@config.API_URL}/calendars")

      response.code == 200 ? JSON.parse(response, object_class: OpenStruct).data : nil
    end

    # Save Calendar to Database
    def save(account_id:, calendars:) # rubocop:disable Metrics/MethodLength
      calendar_lists = []
      calendars.each do |calendar|
        next unless calendar.access_role == 'owner'

        calendar_lists.push(
          {
            gid: calendar.gid,
            summary: calendar.summary,
            description: calendar.description,
            location: calendar.location,
            time_zone: calendar.time_zone,
            access_role: calendar.access_role
          }
        )
      end

      response = HTTP.post("#{@config.API_URL}/accounts/#{account_id}/calendars", json: calendar_lists)

      raise('Save failed') unless response.code == 201

      JSON.parse(response.body)
    end

    # Get Common Busy Time
    def list_common_busy_time(current_account:, group_id:, calendar_mode:, date:, credentials:) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      datetime = "#{DateTime.parse(date).year}-#{DateTime.parse(date).month}-#{DateTime.parse(date).day}"

      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .post("#{@config.API_URL}/groups/#{group_id}/common-busy-time/#{calendar_mode}/#{datetime}",
                           json: { client_id: credentials.client_id,
                                   client_secret: credentials.client_secret,
                                   scope: credentials.scope,
                                   access_token: credentials.access_token,
                                   refresh_token: credentials.refresh_token,
                                   expires_at: credentials.expires_at,
                                   grant_type: credentials.grant_type })

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
