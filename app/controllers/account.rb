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

      routing.on do
        # GET /account/login
        routing.get String do |username|
          if @current_account && @current_account['username'] == username
            view :account, locals: { current_account: @current_account }
          else
            routing.redirect @login_route
          end
        end
      end
    end
  end
end
