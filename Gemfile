# frozen_string_literal: true

source 'https://rubygems.org'
ruby File.read('.ruby-version').strip

# Web
gem 'puma'
gem 'roda'
gem 'slim'

# Configuration
gem 'figaro'
gem 'rake'

# Debugging
gem 'pry'

# Communication
gem 'http'
gem 'net-http'

# Security
gem 'bundler-audit'
gem 'rbnacl' # assumes libsodium package already installed
gem 'secure_headers'

# Validation
gem 'dry-validation'

# Google
gem 'google-api-client'
gem 'google-apis-calendar_v3'
gem 'google-apis-oauth2_v2'
gem 'googleauth'

# Https
gem 'rack-ssl-enforcer'

# Session
gem 'redis-rack'

# Development
group :development do
  gem 'rubocop'
  gem 'rubocop-performance'
end

group :development, :test do
  gem 'rack-test'
  gem 'rerun'
end
