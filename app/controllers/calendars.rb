# frozen_string_literal: true

require 'roda'

module CalendarCoordinator
  # Web controller for Credence API
  class App < Roda
    route('calendars') do |routing|
      routing.redirect 'auth/login' unless @current_account.logged_in?

      # GET /calendars
      routing.get do
        calendar_list = CalendarService.new(App.config).list_calendars(@current_account)
        view :owned_calendars,
             locals: { current_user: @current_account, calendars: calendar_list }
      end
    end
  end
end
