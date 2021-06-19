# frozen_string_literal: true

require 'roda'
require_relative './app'

module CalendarCoordinator
  # Web controller for CalendarCoordinator API
  class App < Roda
    route('account') do |routing| # rubocop:disable Metrics/BlockLength
      @login_route = '/auth/login'

      routing.on 'register' do
        # GET /account/register
        routing.get do
          view :register
        end

        # POST /account/register/{registration_token}
        routing.post String do |registration_token|
          account = SecureMessage.decrypt(registration_token)
          raise('account is nil') unless account

          AccountService.new(App.config).register(
            username: account['username'],
            email: account['email'],
            password: routing.params['password']
          )

          flash[:notice] = 'Register success, you can login now!'
          routing.redirect @login_route
        rescue InvalidAcountError
          flash[:error] = 'This Account can not be registered.'
          routing.redirect '/auth/register'
        rescue StandardError
          flash[:error] = 'Register failed, please try again'
          routing.redirect '/account/register'
        end
      end

      routing.redirect @login_route unless @current_account.logged_in?

      # GET /account/{username}
      routing.get String do |username|
        account_detail = GetAccountDetails.new(App.config).call(@current_account)
        user_id = @current_account.email

        # Google OAuth2
        authorizer = Google::Auth::WebUserAuthorizer.new(CLIENT_ID, SCOPE, TOKEN_STORE)
        credentials = authorizer.get_credentials(user_id, request)
        routing.redirect authorizer.get_authorization_url(login_hint: user_id, request: request) unless credentials

        google_credentials = GoogleCredentials.new(credentials)
        calendar_list = CalendarService.new(App.config).list_calendar(@current_account, google_credentials)

        previous_path = CurrentSession.new(session).location

        if @current_account.username == username
          view :account, locals: { account_detail: account_detail,
                                   calendars: calendar_list,
                                   previous_path: previous_path }
        else
          routing.redirect @login_route
        end
      end
    end
  end
end
