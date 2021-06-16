# frozen_string_literal: true

module CalendarCoordinator
  # Convert From Google::Auth::UserRefreshCredentials
  class GoogleCredentials
    def initialize(credentials)
      @client_id = credentials.client_id
      @client_secret = credentials.client_secret
      @scope = credentials.scope
      @access_token = credentials.access_token
      @refresh_token = credentials.refresh_token
      @expires_at = credentials.expires_at
      @grant_type = credentials.grant_type
    end

    attr_reader :client_id, :client_secret, :scope, :access_token, :refresh_token, :expires_at, :grant_type

    def to_json(options = {}) # rubocop:disable Metrics/MethodLength
      JSON(
        {
          client_id: client_id,
          client_secret: client_secret,
          scope: scope,
          access_token: access_token,
          refresh_token: refresh_token,
          expires_at: expires_at,
          grant_type: grant_type
        },
        options
      )
    end
  end
end
