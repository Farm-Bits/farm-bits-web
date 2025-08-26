class UserArea::MyAccountController < UserArea::ApplicationController

  def index
    render inertia: 'UserArea/Profile'
  end

  def update
    if user_params[:password].present?
      if !current_user.valid_password?(user_params[:current_password])
        render inertia: 'UserArea/Profile', props: {
          errors: ['Current password is incorrect']
        }
      else
        if current_user.update(password_params)
          bypass_sign_in(current_user)
          redirect_to user_my_account_path
        else
          render inertia: 'UserArea/Profile', props: {
            errors: current_user.errors.full_messages
          }
        end
      end
    else
      if current_user.update(profile_params)
        redirect_to user_my_account_path
      else
        render inertia: 'UserArea/Profile', props: {
          errors: current_user.errors.full_messages
        }
      end
    end
  end

  def destroy
    if !current_user.valid_password?(user_params[:password])
      render inertia: 'UserArea/Profile', props: {
        errors: ['Current password is incorrect']
      }
      return
    end

    if current_user.update(active: false)
      sign_out(current_user)
      redirect_to root_path, notice: 'Your account has been deactivated.'
    else
      render inertia: 'UserArea/Profile', props: {
        errors: current_user.errors.full_messages
      }
    end
  end

  private
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :current_password)
    end

    def profile_params
      user_params.slice(:name, :email)
    end

    def password_params
      user_params.slice(:password, :password_confirmation)
    end
end
