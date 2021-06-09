# frozen_string_literal: true

require 'roda'
require_relative './app'

module CalendarCoordinator
  # Web controller for CalendarCoordinator API
  class App < Roda
    route('group') do |routing| # rubocop:disable Metrics/BlockLength
      routing.redirect 'auth/login' unless @current_account.logged_in?

      # GET /group/create
      routing.is 'create' do
        routing.get do
          view :group_create
        end
      end

      routing.on String do |group_id| # rubocop:disable Metrics/BlockLength
        routing.on 'calendar' do # rubocop:disable Metrics/BlockLength
          # GET /group/{group_id}/calendar/list
          routing.is 'list' do
            routing.get do
              group_service = GroupService.new(App.config)
              @calendar_list = group_service.owned_calendars(group_id: group_id)

              view 'calendar_list', locals: { calendar_list: @calendar_list }
            rescue StandardError
              view 'calendar_list'
            end
          end

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
        end
      end

      # GET /group
      routing.get do
        group_service = GroupService.new(App.config)
        @group_list = group_service.list(current_account: @current_account)

        view :group, locals: { current_user: @current_account, group_list: @group_list }
      rescue StandardError
        view :group
      end

      # POST /group
      routing.post do
        group_data = routing.params

        group_service = GroupService.new(App.config)
        group_service.create(current_account: @current_account, group: group_data)

        flash[:notice] = 'Group created!'
        routing.redirect '/group'
      rescue StandardError => e
        puts e.full_message
        flash[:error] = 'Create Group failed, please try again'
        routing.redirect '/group/create'
      end
    end
  end
end
