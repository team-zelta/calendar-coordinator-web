# frozen_string_literal: true

require 'roda'
require 'googleauth'
require 'googleauth/stores/redis_token_store'
require 'google/apis/calendar_v3'
require 'date'
require 'fileutils'
require_relative './app'
require_relative '../services/google_auth_service'

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

        credentials = GoogleAuthService.oauth2(routing, user_id, request, CLIENT_ID, SCOPE, TOKEN_STORE)

        calendar = Google::Apis::CalendarV3::CalendarService.new
        calendar.authorization = credentials

        routing.redirect '/'
      end
    end

    route('oauth2callback') do |routing|
      target_url = Google::Auth::WebUserAuthorizer.handle_auth_callback_deferred(request)
      routing.redirect target_url
    end
  end
end
