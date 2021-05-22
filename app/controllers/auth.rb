# frozen_string_literal: true

require 'roda'
require_relative './app'

module CalendarCoordinator
  # Web controller for CalendarCoordinator API
  class App < Roda
    route('auth') do |routing|
      @login_route = '/auth/login'
      routing.is 'login' do
        # GET /auth/login
        routing.get do
          view :login
        end

        # POST /auth/login
        routing.post do
          account = AccountService.new(App.config).authenticate(
            username: routing.params['username'],
            password: routing.params['password']
          )
          SecureSession.new(session).set(:current_account, account)
          flash[:notice] = "Welcome back #{account['username']}!"
          routing.redirect '/'
        rescue StandardError
          flash[:error] = 'Username and password did not match our records'
          routing.redirect @login_route
        end
      end

      routing.on 'logout' do
        routing.get do
          SecureSession.new(session).delete(:current_account)
          routing.redirect @login_route
        end
      end
    end
  end
end
