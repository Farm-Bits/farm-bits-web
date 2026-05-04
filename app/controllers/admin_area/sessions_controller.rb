class AdminArea::SessionsController < AdminArea::ApplicationController
  def index
    sessions = current_admin_user.user_sessions.active.order(last_seen_at: :desc)

    render inertia: 'Login/Sessions/Index', props: {
      sessions: UserSessionSerializer.render_as_json(
        sessions,
        current_session_id: current_user_session&.id
      )
    }
  end

  def destroy
    user_session = current_admin_user.user_sessions.active.find(params[:id])
    user_session.revoke!

    if user_session.id == current_user_session&.id
      sign_out current_admin_user
      redirect_to new_admin_user_session_path, notice: 'Signed out.'
      return
    end

    redirect_to admin_sessions_path, notice: 'Session revoked.'
  end

  def destroy_all
    others = current_admin_user.user_sessions.active.where.not(id: current_user_session&.id)
    others.find_each(&:revoke!)

    redirect_to admin_sessions_path, notice: 'Signed out of all other sessions.'
  end
end
