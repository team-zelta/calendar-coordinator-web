# frozen_string_literal: true

require 'redis'
require_relative 'secure_message'

# Encrypt and Decrypt JSON encoded sessions
class SecureSession
  attr_reader :redis_url

  ## Any use of this library must setup configuration information
  def self.setup(redis_url)
    @redis_url = redis_url
  end

  ## Class methods to create and retrieve cookie salt
  SESSION_SECRET_BYTES = 64

  # Generate secret for sessions
  def self.generate_secret
    SecureMessage.encoded_random_bytes(SESSION_SECRET_BYTES)
  end

  def self.wipe_redis_sessions
    redis = Redis.new(url: @redis_url)
    redis.keys.each { |session_id| redis.del session_id } # rubocop:disable Style/HashEachMethods
  end

  ## Instance methods to store and retrieve encrypted session data
  def initialize(session)
    @session = session
  end

  def set(key, value)
    @session[key] = SecureMessage.encrypt(value)
  end

  def get(key)
    return nil unless @session[key]

    SecureMessage.decrypt(@session[key])
  end

  def delete(key)
    @session.delete(key)
  end
end
