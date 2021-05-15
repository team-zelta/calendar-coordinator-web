# frozen_string_literal: true

require 'rake/testtask'

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
