# frozen_string_literal: true

require 'http'

module CalendarCoordinator
  # Returns an authenticated user, or nil
  class AuthorizeGithubAccount
    # Errors emanating from Github
    class UnauthorizedError < StandardError
      def message
        'Could not login with Github'
      end
    end

    def initialize(config)
      @config = config
    end

    def call(code)
      access_token = get_access_token_from_github(code)
      get_sso_account_from_api(access_token)
    end

    private

    def get_access_token_from_github(code)
      challenge_response =
        HTTP.headers(accept: 'application/json')
            .post(ENV['GITHUB_TOKEN_URL'],
                  form: { client_id: ENV['GITHUB_CLIENT_ID'],
                          client_secret: ENV['GITHUB_CLIENT_SECRET'],
                          code: code })
      raise UnauthorizedError unless challenge_response.status < 400

      JSON.parse(challenge_response)['access_token']
    end

    def get_sso_account_from_api(access_token)
      response =
        HTTP.post("#{@config.API_URL}/auth/sso/github",
                  json: { access_token: access_token })
      raise if response.code >= 400

      account_info = JSON.parse(response)['data']

      {
        account: account_info['account'],
        auth_token: account_info['auth_token']
      }
    end
  end
end
