# frozen_string_literal: true

require 'http'

module CalendarCoordinator
  # Returns an authenticated user, or nil
  class AccountService
    class UnauthorizedError < StandardError; end

    class InvalidAcountError < StandardError; end

    def initialize(config)
      @config = config
    end

    # Account authenticate
    def authenticate(username:, password:)
      response = HTTP.post("#{@config.API_URL}/auth/authenticate",
                           json: { username: username, password: password })
      raise(UnauthorizedError) unless response.code == 200

      JSON.parse(response.body)
    end

    # Account register
    def register(username:, email:, password:)
      response = HTTP.post("#{@config.API_URL}/accounts",
                           json: { username: username, email: email, password: password })

      raise InvalidAcountError unless response.code == 201

      JSON.parse(response.body)
    end
  end
end
