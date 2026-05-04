class AdminArea::ApplicationController < ApplicationController
  before_action :authenticate_admin_user!
  before_action :touch_user_session
  inertia_share do
    {
      userScope: 'admin_users',
      user: current_admin_user
    }
  end

  private
    def current_user_session
      request.env['user_session.current.admin_user']
    end

    def touch_user_session
      session = current_user_session
      if session.nil?
        return
      end

      session.touch_seen!(ip: request.remote_ip, user_agent: request.user_agent)
    end
end
