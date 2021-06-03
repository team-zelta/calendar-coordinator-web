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

      raise(UnauthorizedError) if response.code == 403
      raise(ApiServerError) if response.code != 200

      account_info = JSON.parse(response.to_s)['attributes']

      {
        account: account_info['account']['attributes'],
        auth_token: account_info['auth_token']
      }
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
