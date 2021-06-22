# frozen_string_literal: true

require_relative './account'

module CalendarCoordinator
  # Managing session information
  class CurrentSession
    def initialize(session)
      @secure_session = SecureSession.new(session)
    end

    def current_account
      Account.new(@secure_session.get(:account),
                  @secure_session.get(:auth_token))
    end

    def current_account=(current_account)
      @secure_session.set(:account, current_account.account_info)
      @secure_session.set(:auth_token, current_account.auth_token)
    end

    def delete
      @secure_session.delete(:account)
      @secure_session.delete(:auth_token)
    end

    # Page path for redirect
    def store_location=(path)
      @secure_session.set(:return_to, path)
    end

    # Page path for redirect
    def location
      @secure_session.get(:return_to)
    end

    def credentials(account)
      @secure_session.get_google_credentials("g-user-token:#{account.email}")
    end

    def delete_credentials(account)
      @secure_session.delete_google_credentials("g-user-token:#{account.email}")
    end
  end
end
