# frozen_string_literal: true

require 'roda'
require 'slim'

module CalendarCoordinator
  # Base class for CalendarCoordinator Web Application
  class App < Roda
    plugin :render, engine: 'slim', views: 'app/presentation/views'
    plugin :assets, css: 'style.css', path: 'app/presentation/assets'
    plugin :public, root: 'app/presentation/public'
    plugin :multi_route
    plugin :flash

    route do |routing|
      response['Content-Type'] = 'text/html; charset=utf-8'

      @current_account = CurrentSession.new(session).current_account

      routing.public
      routing.assets
      routing.multi_route

      # GET /
      routing.root do
        puts "app #{@current_account.logged_in?}"
        if @current_account.logged_in?
          group_list = GroupService.new(App.config).list(current_account: @current_account)

          routing_url = "/group/#{group_list.first.id}/calendar/week/common-busy-time"
          routing.redirect "#{routing_url}/#{DateTime.now.year}-#{DateTime.now.month}-#{DateTime.now.day}"
        end

        view 'home', locals: { current_account: @current_account }
      rescue StandardError => e
        puts e.full_message
        view 'home', locals: { current_account: @current_account }
      end
    end
  end
end
