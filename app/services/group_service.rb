# frozen_string_literal: true

require 'http'
module CalendarCoordinator
  # Group Service
  class GroupService
    class InvitationError < StandardError; end

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

      raise('Create Group failed') unless response.code == 201
    end

    # Invite account to group
    def invite(current_account, group_id, invitation_data)
      invitation_data['group_id'] = group_id

      invitation_token = SecureMessage.encrypt(invitation_data)
      invitation_data['invitation_url'] = "#{@config.APP_URL}/group/join/#{invitation_token}"

      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .post("#{@config.API_URL}/groups/invite", json: invitation_data)
      raise(InvitationError) unless response.code == 202

      JSON.parse(response.body)
    end

    # Join Group
    def join(current_account, group_id)
      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .post("#{@config.API_URL}/groups/join", json: { group_id: group_id })

      raise('Join Group failed') unless response.code == 201
    end
  end
end
