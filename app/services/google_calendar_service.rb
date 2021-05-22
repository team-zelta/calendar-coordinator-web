# frozen_string_literal: true

require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/redis_token_store'
require 'date'
require 'fileutils'

module GoogleCalendar
  # Google Calendar Service
  class GoogleCalendarService
    TOKEN_PATH = "token.yaml".freeze

    # Get authorizer
    def self.authorizer(scope)
      client_id = Google::Auth::ClientId.new('27551357076-6a99f359fpf69c37g0fsdcf9q5rfc5l7.apps.googleusercontent.com',
                                             '8rZRcYXVTRKK5QnOzJaUMpSn')
      token_store = nil
      authorizer = Google::Auth::WebUserAuthorizer.new(client_id, scope, Google::Auth::Stores::RedisTokenStore.new(redis: Redis.new))
      puts "token_store = #{token_store}"

      authorizer
    end

    # Get credentials
    def self.credentials(authorizer)
      user_id = 'default'
      request = nil
      authorizer.get_credentials(user_id, request)
    end

    # Get authorization_url if no credentials
    def self.authorization_url(user_id:, request:)
      authorizer.get_authorization_url(login_hint: user_id, request: request)
    end
  end
end
