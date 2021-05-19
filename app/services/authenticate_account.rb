# frozen_string_literal: true

require 'http'

module CalendarCoordinator
  # Returns an authenticated user, or nil
  class AuthenticateAccount
    class UnauthorizedError < StandardError; end

    def initialize(config)
      @config = config
    end

    def call(username:, password:)
      response = HTTP.post("#{@config.API_URL}/auth/authenticate",
                           json: { username: username, password: password })
      raise(UnauthorizedError) unless response.code == 200

      JSON.parse(response.body)
    end
  end
end
