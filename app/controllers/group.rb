# frozen_string_literal: true

require 'roda'
require_relative './app'

module CalendarCoordinator
  # Web controller for CalendarCoordinator API
  class App < Roda # rubocop:disable Metrics/ClassLength
    route('group') do |routing| # rubocop:disable Metrics/BlockLength
      routing.redirect 'auth/login' unless @current_account.logged_in?

      # GET /group/create
      routing.is 'create' do
        routing.get do
          view :group_create
        end
      end

      # GET /group/join/{invitation_token}
      routing.on 'join' do
        routing.get String do |invitation_token|
          invitation = SecureMessage.decrypt(invitation_token)
          raise('Join Group failed') unless invitation['email'] == @current_account.email

          group_service = GroupService.new(App.config)
          group_service.join(@current_account, invitation['group_id'])

          flash[:notice] = 'Join Group Success!'
          routing.redirect '/group'
        rescue StandardError => e
          puts e.full_message
          flash[:error] = 'Join Group failed, please contact to the group owner to try again.'
          routing.redirect '/group'
        end
      end

      routing.on String do |group_id| # rubocop:disable Metrics/BlockLength
        routing.is 'invite' do
          # GET /group/{group_id}/invite
          routing.get do
            view :group_invite, locals: { group_id: group_id }
          end

          # POST /group/{group_id}/invite
          routing.post do
            invitation = Form::Invitation.new.call(routing.params)
            if invitation.failure?
              flash[:error] = Form.validation_errors(invitation)
              routing.redirect "/group/#{group_id}/invite"
            end

            GroupService.new(App.config).invite(@current_account, group_id, invitation.to_h)

            flash[:notice] = 'Invitation email has sent.'
            routing.redirect '/group'
          rescue StandardError => e
            puts "Send Invitation email failed: #{e.inspect}"
            puts e.full_message
            flash[:error] = 'Invitation failed, please try again.'
            routing.redirect @register_route
          end
        end

        routing.on 'calendar' do # rubocop:disable Metrics/BlockLength
          # GET /group/{group_id}/calendar/list
          routing.is 'list' do
            routing.get do
              group_service = GroupService.new(App.config)
              owned_calendars = group_service.owned_calendars(group_id: group_id)
              @calendar_list = owned_calendars.calendars

              view :calendar_list, locals: { group: owned_calendars.group }
            rescue StandardError
              view :calendar_list
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

                group_service = GroupService.new(App.config)
                @group = group_service.get(@current_account, group_id)
                @account_calendar = group_service.get_assign_calendar_by_account(@current_account,
                                                                                 group_id,
                                                                                 @current_account.id)

                view 'events'
              rescue StandardError
                view 'events'
              end
            end
          end
        end

        # GET /group/{group_id}/setting
        routing.is 'setting' do
          routing.get do
            @group_members = GroupService.new(App.config).owned_accounts(group_id: group_id)
            @group = GroupService.new(App.config).get(@current_account, group_id)

            view :group_setting, locals: { group_id: group_id }
          end
        end

        routing.on 'account' do
          routing.on String do |account_id|
            routing.is 'delete' do
              # GET /group/{group_id}/account/{account_id}/delete
              routing.get do
                GroupService.new(App.config).delete_account(@current_account, group_id, account_id)

                flash[:notice] = 'Delete user successful!'
                routing.redirect "/group/#{group_id}/setting"
              rescue StandardError
                flash[:error] = 'Delete user failed!'
                routing.redirect "/group/#{group_id}/setting"
              end
            end
          end
        end

        # GET /group/{group_id}/delete
        routing.is 'delete' do
          routing.get do
            GroupService.new(App.config).delete(@current_account, group_id)

            flash[:notice] = 'Delete group successful!'
            routing.redirect '/group'
          rescue StandardError
            flash[:error] = 'Delete group failed!'
            routing.redirect '/group'
          end
        end

        # post /group/{group_id}/update
        routing.is 'update' do
          routing.post do
            group = GroupService.new(App.config).get(@current_account, group_id)
            group.groupname = routing.params['groupname']

            GroupService.new(App.config).update(current_account: @current_account, group: group.to_h)

            flash[:notice] = 'Update group name successful!'
            routing.redirect "/group/#{group_id}/setting"
          rescue StandardError => e
            puts e.full_message
            flash[:error] = 'Update group name failed!'
            routing.redirect "/group/#{group_id}/setting"
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
