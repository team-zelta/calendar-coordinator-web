# frozen_string_literal: true

require 'date'
require_relative 'event'

module Views
  # Class to parse the events got from /common-busy-time into Views::Event
  class EventList
    attr_reader :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday

    def initialize(events)
      @events = events.map { |event| Event.new(event) }
      @monday = []
      @tuesday = []
      @wednesday = []
      @thursday = []
      @friday = []
      @saturday = []
      @sunday = []
      events_to_weekday
    end

    def events_to_weekday
      # now = DateTime.now
      # filter out the events start before 9 and after 19
      # events_worktime = @events.reject { |event| event.start_time.hour < 9 || event.start_time.hour > 19 }

      # if the end time is after 19, only show it to 19
      # events_worktime.map! do |event|
      #   if event.end_time.hour >= 19
      #     event.end_time = DateTime.new(now.year, now.month, now.day, 19, 0, 0, now.zone)
      #     event.update_css_timestr
      #   end
      #   event
      # end

      @events.each do |event|
        case event.start_time.wday
        when 0
          @sunday.append(event)
        when 1
          @monday.append(event)
        when 2
          @tuesday.append(event)
        when 3
          @wednesday.append(event)
        when 4
          @thursday.append(event)
        when 5
          @friday.append(event)
        when 6
          @saturday.append(event)
        end
      end
    end
  end
end
