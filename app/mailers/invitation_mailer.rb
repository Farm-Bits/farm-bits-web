class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @inviter = invitation.inviter
    @token = invitation.token
    @expires_at = invitation.expires_at
    @accept_url = invitation.accept_url

    if @invitation.inviter_type == 'User'
      setup_user_invitation
    elsif @invitation.inviter_type == 'AdminUser'
      setup_admin_user_invitation
    else
      Rails.logger.warn "Unknown inviter type: #{@invitation.inviter_type}"
      return
    end

    mail(
      to: @invitation.email,
      subject: @subject,
      template_name: @template_name
    )
  end

  private
    def setup_user_invitation
      @company = @invitation.company
      @role = @invitation.role
      @subject = "You're invited to join #{@company.name}"
      @template_name = 'invite_user'
    end

    def setup_admin_user_invitation
      @subject = 'You\'re invited as a System Administrator'
      @template_name = 'invite_admin_user'
    end
end
