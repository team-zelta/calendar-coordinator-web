# frozen_string_literal: true

require 'http'

module CalendarCoordinator
  # Returns an authenticated user, or nil
  class AuthService
    class VerificationError < StandardError; end

    def initialize(config)
      @config = config
    end

    def send_register_verify_email(registration_data)
      registration_token = SecureMessage.encrypt(registration_data)
      registration_data['verification_url'] = "#{@config.APP_URL}/auth/register/#{registration_token}"

      response = HTTP.post("#{@config.API_URL}/auth/register", json: registration_data)
      raise(VerificationError) unless response.code == 202

      JSON.parse(response.body)
    end
  end
end
