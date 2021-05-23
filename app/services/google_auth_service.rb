# frozen_string_literal: true

require 'googleauth'
require 'googleauth/stores/redis_token_store'
require 'google/apis/calendar_v3'
require 'date'
require 'fileutils'

module GoogleHelper
  # Google Calendar Service
  class GoogleAuthService
    # Google OAuth
    def self.oauth2(routing, user_id, request, client_id, scope, token_store) # rubocop:disable Metrics/ParameterLists
      authorizer = Google::Auth::WebUserAuthorizer.new(client_id, scope, token_store)
      credentials = authorizer.get_credentials(user_id, request)

      routing.redirect authorizer.get_authorization_url(login_hint: user_id, request: request) unless credentials

      credentials
    end
  end
end
