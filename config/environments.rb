# frozen_string_literal: true

require 'delegate'
require 'roda'
require 'figaro'
require 'logger'
require 'rack/ssl-enforcer'
require 'rack/session/redis'
require_relative '../app/lib/secure_session'

module CalendarCoordinator
  # Configuration for the API
  class App < Roda
    plugin :environments

    # Environment variables setup
    Figaro.application = Figaro::Application.new(
      environment: environment,
      path: File.expand_path('config/secrets.yml')
    )
    Figaro.load
    def self.config() = Figaro.env

    # Logger setup
    LOGGER = Logger.new($stderr)
    def self.logger() = LOGGER

    ONE_MONTH = 30 * 24 * 60 * 60

    configure do
      SecureSession.setup(ENV['REDIS_URL']) # REDIS_URL used again below
      SecureMessage.setup(ENV.delete('MSG_KEY'))
    end

    configure :development, :test do
      require 'pry'

      # Allows running reload! in pry to restart entire app
      def self.reload!
        exec 'pry -r ./spec/test_load_all'
      end
    end

    configure :development, :test do
      # use Rack::Session::Cookie,
      #     expire_after: ONE_MONTH, secret: config.SESSION_SECRET

      # use Rack::Session::Pool,
      #     expire_after: ONE_MONTH

      use Rack::Session::Redis,
          expire_after: ONE_MONTH,
          redis_server: {
            url: ENV['REDIS_TLS_URL'], # REDIS_URL used again in google
            ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
          }
    end

    configure :production do
      use Rack::SslEnforcer, hsts: true

      use Rack::Session::Redis,
          expire_after: ONE_MONTH,
          redis_server: {
            url: ENV['REDIS_TLS_URL'], # REDIS_URL used again in google
            ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
          }
    end
  end
end
