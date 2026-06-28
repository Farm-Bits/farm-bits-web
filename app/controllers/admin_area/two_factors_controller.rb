class AdminArea::TwoFactorsController < AdminArea::ApplicationController
  def update
    if !current_admin_user.valid_password?(params[:current_password])
      redirect_to admin_my_account_path(tab: 'security'),
        inertia: { errors: { current_password: 'Incorrect password.' } }
      return
    end

    enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled])

    if enabled
      ActiveRecord::Base.transaction do
        current_admin_user.update!(otp_enabled_at: Time.current)
        current_user_session.mark_otp_verified!
      end

      redirect_to admin_my_account_path(tab: 'security'),
        notice: 'Two-factor authentication enabled.'
    else
      current_admin_user.update!(otp_enabled_at: nil)
      redirect_to admin_my_account_path(tab: 'security'),
        notice: 'Two-factor authentication disabled.'
    end
  end
end
