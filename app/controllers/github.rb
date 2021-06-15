# frozen_string_literal: true

require 'roda'
require_relative './app'

module CalendarCoordinator
  # Web controller for CalendarCoordinator API
  class App < Roda
    @login_route = '/auth/login'

    route('github') do |routing|
      routing.is 'login' do
        scope = 'user:email'
        oauth_params = ["client_id=#{ENV['GITHUB_CLIENT_ID']}", "scope=#{scope}"].join('&')

        routing.redirect "#{ENV['GITHUB_OAUTH_URL']}?#{oauth_params}"
      end
    end

    route('github_callback') do |routing|
      routing.get do
        authorized = AuthorizeGithubAccount.new(App.config)
                                           .call(routing.params['code'])

        current_account = CurrentAccount.new(
          authorized[:account],
          authorized[:auth_token]
        )

        CurrentSession.new(session).current_account = current_account

        flash[:notice] = "Welcome #{current_account.username}!"
        routing.redirect '/'
      rescue AuthorizeGithubAccount::UnauthorizedError
        flash[:error] = 'Could not login with Github'
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
