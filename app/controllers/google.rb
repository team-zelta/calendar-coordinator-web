# frozen_string_literal: true

require 'roda'
require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'date'
require 'fileutils'
require_relative './app'
require_relative '../services/google_calendar_service'

module CalendarCoordinator
  # Web controller for CalendarCoordinator API
  class App < Roda
    include GoogleCalendar
    route('google') do |routing|
      routing.is 'calendar' do
        user_id = 'default'
        request = nil

        calendar = Google::Apis::CalendarV3::CalendarService.new
        authorizer = GoogleCalendarService.authorizer(Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY)
        credentials = GoogleCalendarService.credentials(authorizer)
        routing.redirect GoogleCalendarService.authorization_url(user_id: user_id, request: request) unless credentials

        calendar.authorization = credentials
        routing.redirect @login_route
        calendar_id = 'primary'
        response = calendar.list_events(calendar_id,
                                       max_results: 10,
                                       single_events: true,
                                       order_by: 'startTime',
                                       time_min: Time.now.iso8601)

        puts "Upcoming events:"
        puts "No upcoming events found" if response.items.empty?
        response.items.each do |event|
          start = event.start.date || event.start.date_time
          puts "- #{event.summary} (#{start})"
        end

        view :home
      end
    end
  end
end
