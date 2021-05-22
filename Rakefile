# frozen_string_literal: true

require 'rake/testtask'
require './require_app'

task :print_env do
  puts "Environment: #{ENV['RACK_ENV'] || 'development'}"
end

desc 'Run application console (pry)'
task :console => :print_env do
  sh 'pry -r ./spec/test_load_all'
end

desc 'Check Vulnerable Dependencies'
task :audit do
  sh 'bundle audit check --update'
end

desc 'Check Style and Performance'
task :style do
  sh 'rubocop .'
end

desc 'Test all the specs'
Rake::TestTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.warning = false
end

namespace :run do
  # Run in development mode
  task :dev do
    sh 'rackup -p 9292'
  end
end

task :load_lib do
  require_app('lib')
end

namespace :generate do
  desc 'Create rbnacl key'
  task :msg_key => :load_lib do
    puts "New MSG_KEY (base64): #{SecureMessage.generate_key}"
  end

  desc 'Create cookie secret'
  task :session_secret => :load_lib do
    puts "New SESSION_SECRET (base64): #{SecureSession.generate_secret}"
  end
end

namespace :session do
  desc 'Wipe all sessions stored in Redis'
  task :wipe => :load_lib do
    require 'redis'
    puts 'Deleting all sessions from Redis session store'
    wiped = SecureSession.wipe_redis_sessions
    puts "#{wiped.count} sessions deleted"
  end
end
