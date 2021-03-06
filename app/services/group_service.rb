# frozen_string_literal: true

require 'http'
module CalendarCoordinator
  # Group Service
  class GroupService
    class InvitationError < StandardError; end

    def initialize(config)
      @config = config
    end

    # Get Group
    def get(current_account, group_id)
      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .get("#{@config.API_URL}/groups/#{group_id}")

      raise('Failed to Get Group') unless response.code == 200

      JSON.parse(response.body, object_class: OpenStruct)
    end

    # Get Group Owned Calendars
    def owned_calendars(group_id:)
      response = HTTP.get("#{@config.API_URL}/groups/#{group_id}/calendars")
      raise('Failed to Get Owned Calendars') unless response.code == 200

      JSON.parse(response.body, object_class: OpenStruct)
    end

    # Get Group Owned Calendars Account email
    def owned_calendars_account_emails(group_id:)
      response = HTTP.get("#{@config.API_URL}/groups/#{group_id}/calendar-account-email")
      raise('Failed to Get Owned Calendars') unless response.code == 200

      JSON.parse(response.body)
    end

    # Get Group Owned Accounts
    def owned_accounts(group_id:)
      response = HTTP.get("#{@config.API_URL}/groups/#{group_id}/accounts")
      raise('Failed to Get Owned Accounts') unless response.code == 200

      JSON.parse(response.body, object_class: OpenStruct)
    end

    # Get all Groups
    def list(current_account:)
      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .get("#{@config.API_URL}/groups")
      raise('Failed to Get Group List') unless response.code == 200

      JSON.parse(response.body, object_class: OpenStruct)
    end

    # Create Group
    def create(current_account:, group:)
      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .post("#{@config.API_URL}/groups", json: group)

      raise('Failed to Create Group') unless response.code == 201

      JSON.parse(response.body, object_class: OpenStruct)
    end

    # Update Group
    def update(current_account:, group:)
      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .post("#{@config.API_URL}/groups/#{group[:id]}/update", json: { groupname: group[:groupname] })

      raise('Failed to Update Group') unless response.code == 201
    end

    # Invite account to group
    def invite(current_account, group_id, invitation_data)
      invitation_data['group_id'] = group_id

      invitation_token = SecureMessage.encrypt(invitation_data)
      invitation_data['invitation_url'] = "#{@config.APP_URL}/group/join/#{invitation_token}"

      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .post("#{@config.API_URL}/groups/invite", json: invitation_data)

      response_body = JSON.parse(response.body)
      raise(InvitationError, response_body['message']) unless response.code == 202
    end

    # Join Group
    def join(current_account, group_id)
      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .post("#{@config.API_URL}/groups/join", json: { group_id: group_id })

      raise('Failed to Join Group') unless response.code == 201
    end

    # Delete Group
    def delete(current_account, group_id)
      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .get("#{@config.API_URL}/groups/#{group_id}/delete")

      raise('Failed to Join Group') unless response.code == 200
    end

    # Delete account from group
    def delete_account(current_account, group_id, account_id)
      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .get("#{@config.API_URL}/groups/#{group_id}/accounts/#{account_id}/delete")

      raise('Failed to delete account from group') unless response.code == 200
    end

    # Get Assign Calendar by Account
    def get_assign_calendar_by_account(current_account, group_id, account_id)
      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .get("#{@config.API_URL}/groups/#{group_id}/accounts/#{account_id}/calendar")

      raise('Failed to Get Assign Calendar by Account') unless response.code == 200

      JSON.parse(response.body)
    end

    # Add calendar to group
    def add_calendar(current_account, group_id, calendar_id)
      response = HTTP.auth("Bearer #{current_account.auth_token}")
                     .post("#{@config.API_URL}/groups/add-calendar", json: { group_id: group_id,
                                                                             calendar_id: calendar_id })

      raise('Failed to Add Calendar') unless response.code == 201
    end
  end
end
