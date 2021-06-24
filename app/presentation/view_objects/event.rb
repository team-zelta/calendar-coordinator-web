# frozen_string_literal: true

# View Object
require 'date'

module Views
  # evnet object that shows on event.slim
  class Event
    CALENDAR_START_HOUR = 6
    CALENDAR_ROW_HEIGHT = 50 # height for a row of 30 minutes
    CALENDAR_ROW_MINUTE = 30

    attr_accessor :summary, :height, :top, :start_time, :end_time, :start_time_str, :end_time_str

    def initialize(event)
      @summary = event.summary || nil
      @start_time = DateTime.parse(event.start_date_time)
      @end_time = DateTime.parse(event.end_date_time)
      adjust_to_worktime
      update_css_timestr
    end

    def adjust_to_worktime
      # if the event cross the day, we limit the end time to the midnight of the same day
      if @end_time.day != @start_time.day
        @end_time = DateTime.new(@start_time.year, @start_time.month, @start_time.day, 23, 59, 0, @start_time.zone)
        puts "==DEBUG== new @end_time set to: #{@end_time}"
      end

      # if an event begin before 6 and end after 6, limit the start time to 6
      if @start_time.hour < 6 && @end_time.hour >= 6 # rubocop:disable Style/GuardClause
        @start_time = DateTime.new(@start_time.year, @start_time.month, @start_time.day, 6, 0, 0,
                                   @start_time.zone)
      end
    end

    def update_css_timestr
      setup_css_attribute
      parse_time_to_str
    end

    def setup_css_attribute
      calc_top
      calc_height
    end

    def calc_top
      # Example: 10:10 would get minite_to_top = 250, @top would be 416
      minute_to_top = (@start_time.hour - CALENDAR_START_HOUR) * 60 + @start_time.minute
      @top = ((minute_to_top.to_f / CALENDAR_ROW_MINUTE) * CALENDAR_ROW_HEIGHT).to_i
    end

    def calc_height
      # Example: 10:30-11:30, @height would be 100
      elapsed_minute = ((@end_time - @start_time) * 24 * 60).to_i
      @height = ((elapsed_minute.to_f / CALENDAR_ROW_MINUTE) * CALENDAR_ROW_HEIGHT).to_i
    end

    def parse_time_to_str
      @start_time_str = @start_time.strftime('%k:%M')
      @end_time_str = @end_time.strftime('%k:%M')
    end
  end
end
