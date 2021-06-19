# frozen_string_literal: true

module CalendarCoordinator
  # Behaviors of the currently logged in account
  class Account
    def initialize(account_info, auth_token)
      @account_info = account_info
      @auth_token = auth_token
    end

    attr_reader :account_info, :auth_token

    def id
      @account_info ? @account_info['id'] : nil
    end

    def username
      @account_info ? @account_info['username'] : nil
    end

    def email
      @account_info ? @account_info['email'] : nil
    end

    def logged_out?
      @account_info.nil?
    end

    def logged_in?
      !logged_out?
    end
  end
end
