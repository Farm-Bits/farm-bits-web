class AdminArea::MyAccountController < AdminArea::ApplicationController

  def show
    render inertia: 'MyAccount/index', props: {
      sessions: load_sessions_for_security_tab
    }
  end

  def update
    if user_params[:password].present?
      if !current_admin_user.valid_password?(user_params[:current_password])
        render inertia: 'MyAccount/index', props: {
          sessions: load_sessions_for_security_tab,
          errors: ['Current password is incorrect']
        }
      else
        if current_admin_user.update(password_params)
          bypass_sign_in(current_admin_user)
          redirect_to admin_my_account_path
        else
          render inertia: 'MyAccount/index', props: {
            sessions: load_sessions_for_security_tab,
            errors: current_admin_user.errors.full_messages
          }
        end
      end
    else
      if current_admin_user.update(profile_params)
        redirect_to admin_my_account_path
      else
        render inertia: 'MyAccount/index', props: {
          sessions: load_sessions_for_security_tab,
          errors: current_admin_user.errors.full_messages
        }
      end
    end
  end

  def destroy
    if !current_admin_user.valid_password?(user_params[:password])
      render inertia: 'MyAccount/index', props: {
        sessions: load_sessions_for_security_tab,
        errors: ['Current password is incorrect']
      }
      return
    end

    if current_admin_user.update(active: false)
      sign_out(current_admin_user)
      redirect_to root_path, notice: 'Your account has been deactivated.'
    else
      render inertia: 'MyAccount/index', props: {
        sessions: load_sessions_for_security_tab,
        errors: current_admin_user.errors.full_messages
      }
    end
  end

  private
    # The shared MyAccount Vue components submit account fields under the :user
    # key regardless of scope, so we read the same key here.
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :current_password)
    end

    def profile_params
      user_params.slice(:name, :email)
    end

    def password_params
      user_params.slice(:password, :password_confirmation)
    end

    def load_sessions_for_security_tab
      current_admin_user.user_sessions.active.order(last_seen_at: :desc)
    end
end
