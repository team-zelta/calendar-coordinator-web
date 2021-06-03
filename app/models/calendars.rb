# frozen_string_literal: true

require_relative 'calendar'

module CalendarCoordinator
  # Behaviors of the currently logged in account
  class Calendars
    attr_reader :all

    def initialize(calendars_list)
      @all = calendars_list.map do |calendar|
        Calendar.new(calendar)
      end
    end
  end
end
