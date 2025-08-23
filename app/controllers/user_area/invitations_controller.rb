class UserArea::InvitationsController < UserArea::ApplicationController
  before_action :ensure_can_manage_users!, only: [:index, :create, :resend, :destroy]
  before_action :find_invitation, only: [:resend, :destroy]

  def index
    invitations = current_client.invitations
      .where.not(status: 'accepted')
      .order(created_at: :desc)
    render json: InvitationSerializer.render(invitations)
  end

  def create
    invitation = Invitation.new(invitation_params)
    invitation.inviter = current_user
    invitation.client = current_client

    if invitation.save
      render json: { message: 'Invitation sent successfully' }, status: :created
    else
      render json: { error: invitation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def resend
    result = @invitation&.resend
    if result && result[:success]
      render json: { message: 'Invitation resent successfully' }
    else
      render json: { error: 'Cannot resend this invitation' }, status: :unprocessable_entity
    end
  end

  def accept
    invitation = Invitation.find_by!(token: params[:token])
    result = invitation&.accept!(current_user)
    if result && result[:success]
      redirect_to root_path
    else
      render inertia: 'Login/Sessions/New', props: {
        userScope: 'users',
        errors: [result[:error]]
      }
    end
  end

  def destroy
    @invitation.destroy
    render json: { message: 'Invitation cancelled successfully' }
  end

  private
    def invitation_params
      params.require(:invitation).permit(:email, :role)
    end

    def find_invitation
      @invitation = current_client.invitations.find(params[:id])
    end

    def ensure_can_manage_users!
      if !current_client.role_for(current_user).can_manage_users?
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
end
