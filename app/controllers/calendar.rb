# frozen_string_literal: true

require 'roda'
require_relative './app'

module CalendarCoordinator
  # Web controller for CalendarCoordinator API
  class App < Roda
    route('calendar') do |routing|
      routing.on 'week/group' do
        # GET /calendar/week/group/{group_id}
        routing.on String do |group_id|
          group_service = GroupService.new(App.config)
          @calendar_list = group_service.owned_calendars(group_id: group_id)

          view 'calendar', locals: { calendar_list: @calendar_list }
        rescue StandardError
          view 'calendar'
        end
      end
    end
  end
end
