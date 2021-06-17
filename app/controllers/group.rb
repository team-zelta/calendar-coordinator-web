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

              @account_calendar = group_service.get_assign_calendar_by_account(@current_account,
                                                                               group_id,
                                                                               @current_account.id)

              if @account_calendar.count.zero?
                @current_account_calendars = CalendarService.new(App.config).list_calendars(@current_account)
              end

              view :calendar_list, locals: { group: owned_calendars.group, group_id: group_id }
            rescue StandardError => e
              puts e.full_message
              view :calendar_list
            end
          end

          routing.is 'add' do
            # GET /group/{group_id}/calendar/add
            routing.post do
              calendar_id = routing.params['calendar-radios']
              GroupService.new(App.config).add_calendar(@current_account, group_id, calendar_id)

              flash[:notice] = 'Add calendar success!'

              routing.redirect "/group/#{group_id}/setting"
            rescue StandardError => e
              puts e.full_message
              flash[:errot] = 'Add calendar failed, please try again.'

              routing.redirect "/group/#{group_id}/setting"
            end
          end

          routing.on String do |calendar_mode| # rubocop:disable Metrics/BlockLength
            routing.on String do |event_type| # rubocop:disable Metrics/BlockLength
              # GET /group/{group_id}/calendar/{calendar_mode}/{event_type}/{date}
              routing.get(String) do |date| # rubocop:disable Metrics/BlockLength
                user_id = @current_account.email

                # Google OAuth2
                authorizer = Google::Auth::WebUserAuthorizer.new(CLIENT_ID, SCOPE, TOKEN_STORE)
                credentials = authorizer.get_credentials(user_id, request)
                unless credentials
                  routing.redirect authorizer.get_authorization_url(login_hint: user_id, request: request)
                end

                google_credentials = GoogleCredentials.new(credentials)

                calendar_service = CalendarService.new(App.config)
                if event_type == 'common-busy-time'
                  @events = calendar_service.list_common_busy_time(current_account: @current_account,
                                                                   group_id: group_id,
                                                                   calendar_mode: calendar_mode,
                                                                   date: date,
                                                                   credentials: google_credentials)
                else
                  @event_list = calendar_service.list_events(current_account: @current_account,
                                                             group_id: group_id,
                                                             calendar_mode: calendar_mode,
                                                             date: date,
                                                             credentials: google_credentials)
                end

                group_service = GroupService.new(App.config)
                @group = group_service.get(@current_account, group_id)
                @account_calendar = group_service.get_assign_calendar_by_account(@current_account,
                                                                                 group_id,
                                                                                 @current_account.id)

                # day or week
                @calendar_start_date = if calendar_mode == 'day'
                                         DateTime.parse(date)
                                       else
                                         DateTime.parse(date) - DateTime.parse(date).wday
                                       end
                @calendar_mode_date = calendar_mode == 'day' ? 1 : 7

                @group_list = group_service.list(current_account: @current_account)

                view 'events', locals: { calendar_mode: calendar_mode, event_type: event_type }
              rescue StandardError => e
                puts e.full_message
                view 'events', locals: { calendar_mode: calendar_mode, event_type: event_type }
              end
            end
          end
        end

        # GET /group/{group_id}/setting
        routing.is 'setting' do
          routing.get do
            @group_members = GroupService.new(App.config).owned_accounts(group_id: group_id)
            @account_calendar = GroupService.new(App.config).get_assign_calendar_by_account(@current_account,
                                                                                            group_id,
                                                                                            @current_account.id)
            @current_account_calendars = CalendarService.new(App.config).list_calendars(@current_account)

            @members_calendars = []
            @group_members.each do |member|
              calendar = GroupService.new(App.config).get_assign_calendar_by_account(@current_account,
                                                                                     group_id,
                                                                                     member.id)
              calendar = calendar.empty? ? '' : calendar.first

              @members_calendars.push(
                { member_id: member.id, username: member.username, calendar: calendar }
              )
            end

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

                flash[:notice] = 'Delete user success!'
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

            flash[:notice] = 'Delete group success!'
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

            flash[:notice] = 'Update group name success!'
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
        group = group_service.create(current_account: @current_account, group: group_data)

        flash[:notice] = 'Group created!'
        routing_url = "/group/#{group.group_id}/calendar/week/common-busy-time"
        routing.redirect "#{routing_url}/#{DateTime.now.year}-#{DateTime.now.month}-#{DateTime.now.day}"
      rescue StandardError => e
        puts e.full_message
        flash[:error] = 'Create Group failed, please try again'
        routing.redirect '/group/create'
      end
    end
  end
end
