# frozen_string_literal: true

require 'roda'
require 'googleauth'
require 'googleauth/stores/redis_token_store'
require 'google/apis/calendar_v3'
require 'date'
require 'fileutils'
require_relative './app'
require_relative '../services/google_calendar_service'

module CalendarCoordinator
  # Web controller for CalendarCoordinator API
  class App < Roda
    include GoogleCalendar
    route('google') do |routing| # rubocop:disable Metrics/BlockLength
      routing.is 'calendar' do # rubocop:disable Metrics/BlockLength
        user_id = 'default'

        client_id = Google::Auth::ClientId
                    .new('27551357076-6a99f359fpf69c37g0fsdcf9q5rfc5l7.apps.googleusercontent.com',
                         '8rZRcYXVTRKK5QnOzJaUMpSn')
        scope = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY
        token_store = Google::Auth::Stores::RedisTokenStore.new(redis: Redis.new(url: App.config.REDIS_URL))

        authorizer = Google::Auth::WebUserAuthorizer.new(client_id, scope, token_store)
        credentials = authorizer.get_credentials(user_id, request)

        routing.redirect authorizer.get_authorization_url(login_hint: user_id, request: request) unless credentials

        calendar = Google::Apis::CalendarV3::CalendarService.new
        calendar.authorization = credentials

        calendar_id = 'primary'
        @events = calendar.list_events(calendar_id,
                                       max_results: 10,
                                       single_events: true,
                                       order_by: 'startTime',
                                       time_min: Time.now.iso8601)

        @events.items.each do |event|
          start = event.start.date || event.start.date_time
          puts "- #{event.summary} (#{start})"
        end

        routing.redirect '/'
      end
    end

    route('oauth2callback') do |routing|
      target_url = Google::Auth::WebUserAuthorizer.handle_auth_callback_deferred(request)
      routing.redirect target_url
    end
  end
end
