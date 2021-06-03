# frozen_string_literal: true

require 'roda'

module CalendarCoordinator
  # Web controller for Credence API
  class App < Roda
    route('calendars') do |routing|
      routing.on do
        # GET /calendars/
        routing.get do
          if @current_account.logged_in?
            calendar_list = CalendarService.new(App.config).list_calendars(@current_account)
            calendars = Calendars.new(calendar_list)

            view :owned_calendars,
                 locals: { current_user: @current_account, calendars: calendars }
          else
            routing.redirect '/auth/login'
          end
        end
      end
    end
  end
end
