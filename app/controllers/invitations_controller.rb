class InvitationsController < ApplicationController

  def accept
    invitation = Invitation.find_by(token: params[:token])

    if !invitation
      redirect_to root_path, alert: 'Invalid invitation'
      return
    end

    case invitation.inviter_type
    when 'User'
      existing_user = User.find_by(email: invitation.email)
    when 'AdminUser'
      existing_user = AdminUser.find_by(email: invitation.email)
    else
      redirect_to root_path, alert: 'Invalid invitation type'
      return
    end

    if existing_user
      begin
        result = invitation.accept!(existing_user)
        if result && result[:success]
          sign_in(existing_user)
          if invitation.client_id
            session[:current_client_id] = invitation.client_id
          end
          redirect_to root_path
        else
          resource_name = invitation.inviter_type.underscore.to_sym
          redirect_back(
            fallback_location: new_session_path(resource_name),
            alert: result[:error]
          )
        end
      rescue StandardError => e
        resource_name = invitation.inviter_type.underscore.to_sym
        redirect_back(
          fallback_location: new_session_path(resource_name),
          alert: 'Unable to accept invitation.'
        )
      end
    else
      render inertia: 'Login/Registrations/Invited', props: {
        userScope: invitation.inviter_type.underscore.pluralize,
        invitation: invitation.as_json(only: [:email, :token])
      }
    end
  end

  def sign_up_and_accept
    invitation = Invitation.find_by(token: params[:token])

    if !invitation
      redirect_to root_path, alert: 'Invalid invitation'
      return
    end

    if !['User', 'AdminUser'].include?(invitation.inviter_type)
      redirect_to root_path, alert: 'Invalid invitation type'
      return
    end

    result = nil
    errors = ['Unable to complete invitation acceptance. Please try again.']

    begin
      ActiveRecord::Base.transaction do
        case invitation.inviter_type
        when 'User'
          result = create_and_accept_user(invitation)
        when 'AdminUser'
          result = create_and_accept_admin_user(invitation)
        end

        if !result[:success]
          errors = result[:errors]
          raise ActiveRecord::Rollback
        end
      end
    rescue StandardError => e
      result = { success: false }
    end

    if result && result[:success]
      if invitation.client_id
        session[:current_client_id] = invitation.client_id
      end

      user = result[:user]
      if user.active_for_authentication?
        sign_in(user)
        redirect_to root_path
      else
        resource_name = invitation.inviter_type.underscore.to_sym
        redirect_to new_session_path(resource_name), notice: I18n.t("devise.failure.#{user.inactive_message}")
      end
    else
      render inertia: 'Login/Registrations/Invited', props: {
        token: invitation.token,
        errors: errors
      }
    end
  end

  private
    def sign_up_params
      params.require(:user).permit(:name, :password, :password_confirmation)
    end

    def create_and_accept_user(invitation)
      user_params = sign_up_params.merge(email: invitation.email)
      user = User.new(user_params)

      if !user.save
        return { success: false, errors: user.errors.full_messages }
      end

      begin
        result = invitation.accept!(user)
        if result && result[:success]
          return { success: true, user: user }
        else
          return { success: false, errors: [result[:error] || 'Failed to accept invitation'] }
        end
      rescue StandardError => e
        return { success: false, errors: ['An error occurred while accepting the invitation'] }
      end
    end

    def create_and_accept_admin_user(invitation)
      admin_user_params = sign_up_params.merge(email: invitation.email)
      user = AdminUser.new(admin_user_params)

      if !user.save
        return { success: false, errors: user.errors.full_messages }
      end

      begin
        result = invitation.accept!(user)
        if result && result[:success]
          return { success: true, user: user }
        else
          return { success: false, errors: [result[:error] || 'Failed to accept invitation'] }
        end
      rescue StandardError => e
        return { success: false, errors: ['An error occurred while accepting the invitation'] }
      end
    end
end