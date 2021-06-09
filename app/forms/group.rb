# frozen_string_literal: true

require_relative 'form_base'

module CalendarCoordinator
  module Form
    # Invitation Form Validation
    class Invitation < Dry::Validation::Contract
      config.messages.load_paths << File.join(__dir__, 'errors/group_details.yml')

      params do
        required(:email).filled(format?: EMAIL_REGEX)
      end
    end
  end
end
