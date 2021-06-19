# frozen_string_literal: true

require 'http'

# Returns all projects belonging to an account
class GetAccountDetails
  # Error for accounts that cannot be created
  class InvalidAccount < StandardError
    def message
      'You are not authorized to see details of that account'
    end
  end

  def initialize(config)
    @config = config
  end

  def call(current_account)
    response = HTTP.auth("Bearer #{current_account.auth_token}")
                   .get("#{@config.API_URL}/accounts/#{current_account.id}}")
    raise InvalidAccount if response.code != 200

    auth = JSON.parse(response)
    account_details = auth['account']
    auth_token = auth['auth_token']
    puts "==DEBUG== auth_token #{auth_token.inspect}"
    CalendarCoordinator::Account.new(account_details, auth_token)
  end
end
