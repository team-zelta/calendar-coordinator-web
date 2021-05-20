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

        # POST /account/register
        routing.post do
          account = AccountService.new(App.config).register(
            username: routing.params['username'],
            email: routing.params['email'],
            password: routing.params['password']
          )
          raise('account is nil') unless account

          flash[:notice] = 'Register success, you can login now!'
          routing.redirect @login_route
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
