class AdminArea::SessionsController < AdminArea::ApplicationController
  def destroy
    user_session = current_admin_user.user_sessions.active.find(params[:id])
    user_session.revoke!

    if current_session?(user_session)
      sign_out current_admin_user
      redirect_to new_admin_user_session_path, notice: 'Signed out.'
      return
    end

    redirect_to admin_my_account_path(tab: 'security'), notice: 'Session revoked.'
  end

  def destroy_all
    current_id = current_user_session&.id
    scope = current_admin_user.user_sessions.active
    if current_id.present?
      scope = scope.where.not(id: current_id)
    end

    revoked_count = 0
    scope.find_each do |session|
      session.revoke!
      revoked_count += 1
    end

    if revoked_count == 0
      redirect_to admin_my_account_path(tab: 'security'),
        notice: 'No other sessions to sign out.'
      return
    end

    redirect_to admin_my_account_path(tab: 'security'),
      notice: "Signed out of #{revoked_count} other #{'session'.pluralize(revoked_count)}."
  end

  private
    def current_session?(user_session)
      user_session.id == current_user_session&.id
    end
end
