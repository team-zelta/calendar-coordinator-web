# frozen_string_literal: true

require 'roda'
require 'googleauth'
require 'googleauth/stores/redis_token_store'

module CalendarCoordinator
  # Web controller for Credence API
  class App < Roda
    route('calendars') do |routing|
      routing.redirect 'auth/login' unless @current_account.logged_in?

      routing.is 'check' do
        calendar_list = CalendarService.new(App.config).list_calendars(@current_account)
        if calendar_list.nil? || calendar_list.count.zero?
          view :calendar_check
        else
          routing.redirect '/'
        end
      end

      # GET /calendars
      routing.get do
        current_account = CurrentSession.new(session).current_account
        user_id = current_account.email

        # Google OAuth2
        authorizer = Google::Auth::WebUserAuthorizer.new(CLIENT_ID, SCOPE, TOKEN_STORE)
        credentials = authorizer.get_credentials(user_id, request)
        routing.redirect authorizer.get_authorization_url(login_hint: user_id, request: request) unless credentials

        google_credentials = GoogleCredentials.new(credentials)
        calendar_list = CalendarService.new(App.config).list_calendar(@current_account, google_credentials)

        view :owned_calendars,
             locals: { current_user: @current_account, calendars: calendar_list }
      end
    end
  end
end
