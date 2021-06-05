# frozen_string_literal: true

require 'roda'
require_relative './app'

module CalendarCoordinator
  # Web controller for CalendarCoordinator API
  class App < Roda
    route('group') do |routing| # rubocop:disable Metrics/BlockLength
      routing.on String do |group_id| # rubocop:disable Metrics/BlockLength
        routing.on 'calendar' do # rubocop:disable Metrics/BlockLength
          routing.on String do |calendar_mode|
            routing.on 'common-busy-time' do
              # GET /group/{group_id}/calendar/{calendar_mode}/common-busy-time/{date}
              routing.get(String) do |date|
                calendar_service = CalendarService.new(App.config)
                @common_busy_time = calendar_service.list_common_busy_time(group_id: group_id,
                                                                           calendar_mode: calendar_mode,
                                                                           date: date)

                view 'events_common', locals: { events: @common_busy_time }
              rescue StandardError
                view 'events_common'
              end
            end

            routing.on 'events' do
              # GET /group/{group_id}/calendar/{calendar_mode}/events/{date}
              routing.get(String) do |date|
                calendar_service = CalendarService.new(App.config)
                @event_list = calendar_service.list_events(group_id: group_id,
                                                           calendar_mode: calendar_mode,
                                                           date: date)

                view 'events', locals: { calendar_events: @events_list }
              rescue StandardError
                view 'events'
              end
            end
          end

          # GET /group/{group_id}/calendar/list
          routing.is 'list' do
            group_service = GroupService.new(App.config)
            @calendar_list = group_service.owned_calendars(group_id: group_id)

            view 'calendar_list', locals: { calendar_list: @calendar_list }
          rescue StandardError
            view 'calendar_list'
          end
        end
      end
    end
  end
end