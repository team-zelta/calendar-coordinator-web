# frozen_string_literal: true

require 'googleauth'
require 'googleauth/stores/redis_token_store'
require 'google/apis/calendar_v3'
require 'date'
require 'fileutils'

module GoogleHelper
  # Google Calendar Service
  class GoogleAuthService
    # Get Authorizer from Google OAuth2
    def self.authorizer(client_id, scope, token_store)
      Google::Auth::WebUserAuthorizer.new(client_id, scope, token_store)
    end

    # Get Credentials from Google OAuth2
    def self.credentials(authorizer, user_id, request)
      authorizer.get_credentials(user_id, request)
    end

    # Get Authorization URL from Google OAuth2
    def self.authorization_url(authorizer, user_id, request)
      authorizer.get_authorization_url(login_hint: user_id, request: request) unless credentials
    end
  end
end
