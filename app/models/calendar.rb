# frozen_string_literal: true

module CalendarCoordinator
  # Behaviors of the currently logged in account
  class Calendar
    attr_reader :id, :summary, :description, :location, :time_zone

    def initialize(calendar_info)
      @id = calendar_info['attributes']['id']
      @summary = calendar_info['attributes']['summary']
      @description = calendar_info['attributes']['description']
      @location = calendar_info['attributes']['location']
      @time_zone = calendar_info['attributes']['time_zone']
    end
  end
end
