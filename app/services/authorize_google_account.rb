# frozen_string_literal: true

require 'http'
require 'net/http'

module CalendarCoordinator
  # Returns an authenticated user, or nil
  class AuthorizeGoogleAccount
    # Errors emanating from Google
    class UnauthorizedError < StandardError
      def message
        'Could not login with Google'
      end
    end

    def initialize(config)
      @config = config
    end

    def call(code) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      challenge_response =
        HTTP.headers(accept: 'application/x-www-form-urlencoded')
            .post(ENV['GOOGLE_TOKEN_URL'], form: { code: code,
                                                   client_id: ENV['GOOGLE_CREDENTIALS_CLIENT_ID'],
                                                   client_secret: ENV['GOOGLE_CREDENTIALS_CLIENT_SECRET'],
                                                   redirect_uri: "#{ENV['APP_URL']}/login_oauth2callback",
                                                   grant_type: 'authorization_code' })

      access_token = JSON.parse(challenge_response.body)['access_token']

      response =
        HTTP.post("#{@config.API_URL}/auth/sso/google",
                  json: SignedMessage.sign({ access_token: access_token }))
      raise if response.code >= 400

      account_info = JSON.parse(response)['data']

      {
        account: account_info['account'],
        auth_token: account_info['auth_token']
      }
    end
  end
end
