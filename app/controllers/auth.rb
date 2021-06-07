# frozen_string_literal: true

require 'roda'
require_relative './app'
require_relative '../lib/json_request_body'

module CalendarCoordinator
  # Web controller for CalendarCoordinator API
  class App < Roda
    include Common
    include Form

    route('auth') do |routing| # rubocop:disable Metrics/BlockLength
      @login_route = '/auth/login'
      @register_route = '/account/register'

      routing.is 'login' do
        # GET /auth/login
        routing.get do
          view :login
        end

        # POST /auth/login
        routing.post do
          account_info = AccountService.new(App.config).authenticate(
            username: routing.params['username'],
            password: routing.params['password']
          )

          current_account = CurrentAccount.new(
            account_info[:account],
            account_info[:auth_token]
          )

          CurrentSession.new(session).current_account = current_account

          flash[:notice] = "Welcome back #{current_account.username}!"
          routing.redirect '/'
        rescue StandardError => e
          App.logger.error "UNKOWN ERROR: #{e.message}"
          flash[:error] = 'Username and password did not match our records'
          routing.redirect @login_route
        end
      end

      routing.on 'register' do
        # POST /auth/register
        routing.post do
          registration = Form::Registration.new.call(routing.params)
          if registration.failure?
            flash[:error] = Form.validation_errors(registration)
            routing.redirect @register_route
          end

          AuthService.new(App.config).send_register_verify_email(registration.to_h)

          flash[:notice] = 'Verification email has sent to you email, please check.'
          routing.redirect '/'
        rescue StandardError => e
          puts "Send verification email failed: #{e.inspect}"
          puts e.full_message
          flash[:error] = 'Registeration failed, please try again.'
          routing.redirect @register_route
        end

        # GET /auth/register/{registration_token}
        routing.get(String) do |registration_token|
          flash.now[:notice] = 'Email Verified! Please choose a new password.'
          account = SecureMessage.decrypt(registration_token)
          view :register_confirm, locals: { account: account, registration_token: registration_token }
        end
      end

      routing.on 'logout' do
        # GET /auth/logout
        routing.get do
          CurrentSession.new(session).delete
          routing.redirect @login_route
        end
      end
    end
  end
end
