# frozen_string_literal: true

require 'http'
module CalendarCoordinator
  # Group Service
  class GroupService
    def initialize(config)
      @config = config
    end

    # Get Group Owned Calendars
    def owned_calendars(group_id:)
      response = HTTP.get("#{@config.API_URL}/groups/#{group_id}/calendars")
      raise('Get Owned Calendars failed') unless response.code == 200

      JSON.parse(response.body, object_class: OpenStruct)
    end
  end
end
