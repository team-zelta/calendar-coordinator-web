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
                .new(ENV['GOOGLE_CREDENTIALS_CLIENT_ID'], ENV['GOOGLE_CREDENTIALS_CLIENT_SECRET'])
    SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY
    TOKEN_STORE = Google::Auth::Stores::RedisTokenStore.new(redis: Redis.new(url: ENV['REDIS_TLS_URL'],
                                                                             ssl_params: {
                                                                               verify_mode: OpenSSL::SSL::VERIFY_NONE
                                                                             }))

    route('google') do |routing| # rubocop:disable Metrics/BlockLength
      routing.is 'calendar' do
        current_account = CurrentSession.new(session).current_account
        user_id = current_account.email

        # Google OAuth2
        authorizer = Google::Auth::WebUserAuthorizer.new(CLIENT_ID, SCOPE, TOKEN_STORE)
        credentials = authorizer.get_credentials(user_id, request)
        routing.redirect authorizer.get_authorization_url(login_hint: user_id, request: request) unless credentials

        google_calendar = Google::Apis::CalendarV3::CalendarService.new
        google_calendar.authorization = credentials

        google_credentials = GoogleCredentials.new(credentials)
        # Get calendar list from Google Calendar API
        calendar_list = CalendarService.new(App.config).list_calendar(@current_account, google_credentials)
        # Save calendar to Database
        calendar_service = CalendarService.new(App.config)
        calendar_service.save(account_id: current_account.id, calendars: calendar_list)

        flash[:notice] = 'Connect to Google Calendar Successfully'
        routing.redirect "/account/#{current_account.username}"
      rescue StandardError => e
        puts e.full_message

        flash[:error] = 'Failed to Connect to Google Calendar'
        routing.redirect "/account/#{current_account.username}"
      end

      routing.is 'switch' do
        if CurrentSession.new(session).credentials(@current_account)
          result = CurrentSession.new(session).delete_credentials(@current_account)
          puts result
        end

        routing.redirect '/google/calendar'
      rescue StandardError => e
        puts e.full_message

        flash[:error] = 'Failed to Switch to Google Calendar'
        routing.redirect "/account/#{@current_account.username}"
      end
    end

    route('oauth2callback') do |routing|
      target_url = Google::Auth::WebUserAuthorizer.handle_auth_callback_deferred(request)
      routing.redirect target_url
    end
  end
end
