# frozen_string_literal: true

require 'date'
require_relative 'event'

module Views
  # Class to parse the events got from /common-busy-time into Views::Event
  class UserEventListDay
    attr_reader :username, :events

    def initialize(calendar)
      @username = calendar.username
      @events = calendar.events.map { |event| Event.new(event) }
    end
  end
end
