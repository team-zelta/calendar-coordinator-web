# frozen_string_literal: true

require 'roda'
require 'googleauth'
require 'googleauth/stores/redis_token_store'
require 'google/apis/calendar_v3'
require 'google/apis/oauth2_v2'
require 'google/api_client/client_secrets'
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

        CurrentSession.new(session).store_location = '/'
        flash[:notice] = 'Connect to Google Calendar Successfully'
        routing.redirect "/account/#{current_account.username}"
      rescue StandardError => e
        puts e.full_message

        CurrentSession.new(session).store_location = '/'
        flash[:error] = 'Failed to Connect to Google Calendar'
        routing.redirect "/account/#{current_account.username}"
      end

      routing.is 'switch' do
        if CurrentSession.new(session).credentials(@current_account)
          CurrentSession.new(session).delete_credentials(@current_account)
        end

        routing.redirect '/google/calendar'
      rescue StandardError => e
        puts e.full_message

        flash[:error] = 'Failed to Switch to Google Calendar'
        routing.redirect "/account/#{@current_account.username}"
      end

      routing.is 'login' do
        auth_url = 'https://accounts.google.com/o/oauth2/v2/auth?'
        auth_url += 'scope=https%3A//www.googleapis.com/auth/userinfo.email&'
        auth_url += 'access_type=offline&'
        auth_url += 'include_granted_scopes=true&'
        auth_url += 'response_type=code&'
        auth_url += 'state=state_parameter_passthrough_value&'
        auth_url += "redirect_uri=#{ENV['APP_URL']}/login_oauth2callback&"
        auth_url += "client_id=#{ENV['GOOGLE_CREDENTIALS_CLIENT_ID']}"

        routing.redirect auth_url
      end
    end

    route('oauth2callback') do |routing|
      target_url = Google::Auth::WebUserAuthorizer.handle_auth_callback_deferred(request)
      routing.redirect target_url
    end

    route('login_oauth2callback') do |routing|
      routing.get do
        authorized = AuthorizeGoogleAccount.new(App.config)
                                           .call(routing.params['code'])

        current_account = Account.new(
          authorized[:account],
          authorized[:auth_token]
        )

        CurrentSession.new(session).current_account = current_account

        flash[:notice] = "Welcome #{current_account.username}!"
        routing.redirect '/calendars/check'
      rescue AuthorizeGithubAccount::UnauthorizedError
        flash[:error] = 'Could not login with Google'
        response.status = 403
        routing.redirect @login_route
      rescue StandardError => e
        puts "SSO LOGIN ERROR: #{e.inspect}\n#{e.backtrace}"
        flash[:error] = 'Unexpected API Error'
        response.status = 500
        routing.redirect @login_route
      end
    end
  end
end
