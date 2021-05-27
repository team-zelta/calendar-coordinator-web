# frozen_string_literal: true

require 'roda'
require 'googleauth'
require 'googleauth/stores/redis_token_store'
require 'google/apis/calendar_v3'
require 'date'
require 'fileutils'
require_relative './app'
require_relative '../services/google_auth_service'
require_relative '../services/calendar_service'

module CalendarCoordinator
  # Web controller for CalendarCoordinator API
  class App < Roda
    include GoogleHelper

    CLIENT_ID = Google::Auth::ClientId
                .new('27551357076-6a99f359fpf69c37g0fsdcf9q5rfc5l7.apps.googleusercontent.com',
                     '8rZRcYXVTRKK5QnOzJaUMpSn')
    SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY
    TOKEN_STORE = Google::Auth::Stores::RedisTokenStore.new(redis: Redis.new(url: App.config.REDIS_URL))

    route('google') do |routing|
      routing.is 'calendar' do
        current_account = SecureSession.new(session).get(:current_account)
        user_id = current_account['email']

        # Google OAuth2
        authorizer = GoogleAuthService.authorizer(CLIENT_ID, SCOPE, TOKEN_STORE)
        credentials = GoogleAuthService.credentials(authorizer, user_id, request)
        routing.redirect GoogleAuthService.authorization_url(authorizer, user_id, request) unless credentials

        calendar = Google::Apis::CalendarV3::CalendarService.new
        calendar.authorization = credentials

        # Get calendar list from Google Calendar API
        @calendar_list = calendar.list_calendar_lists

        # Save calendar to Database
        calendar_service = CalendarService.new(App.config)
        calendar_service.save(account_id: current_account['id'], calendars: @calendar_list.items)

        view 'home', locals: { current_account: @current_account }
      end
    end

    route('oauth2callback') do |routing|
      target_url = Google::Auth::WebUserAuthorizer.handle_auth_callback_deferred(request)
      routing.redirect target_url
    end
  end
end
