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

    # Get all Groups
    def list(current_account:)
      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .get("#{@config.API_URL}/groups")
      raise('Get Group List failed') unless response.code == 200

      JSON.parse(response.body, object_class: OpenStruct)
    end

    # Create Group
    def create(current_account:, group:)
      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .post("#{@config.API_URL}/groups", json: group)

      puts response
      raise('Create Group failed') unless response.code == 201
    end
  end
end
