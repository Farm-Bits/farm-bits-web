class UserArea::TwoFactorsController < UserArea::ApplicationController
  skip_after_action :verify_pundit_authorization

  def update
    if !current_user.valid_password?(params[:current_password])
      redirect_to user_my_account_path(tab: 'security'),
        inertia: { errors: { current_password: 'Incorrect password.' } }
      return
    end

    enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled])

    if enabled
      ActiveRecord::Base.transaction do
        current_user.update!(otp_enabled_at: Time.current)
        current_user_session.mark_otp_verified!
      end

      redirect_to user_my_account_path(tab: 'security'),
        notice: 'Two-factor authentication enabled.'
    else
      if current_company.require_2fa?
        redirect_to user_my_account_path(tab: 'security'),
          inertia: { errors: { current_password: 'Your company requires 2FA. It cannot be disabled.' } }
        return
      end

      current_user.update!(otp_enabled_at: nil)
      redirect_to user_my_account_path(tab: 'security'),
        notice: 'Two-factor authentication disabled.'
    end
  end

  private
    def current_user_session
      request.env["user_session.current.#{resource_name}"]
    end

    def resource_name
      :user
    end
end
