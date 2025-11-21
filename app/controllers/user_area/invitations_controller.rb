class UserArea::InvitationsController < UserArea::ApplicationController
  before_action :set_invitation, only: [:resend, :destroy]

  def index
    authorize Invitation, :index?

    invitations = policy_scope(Invitation)
      .where.not(status: 'accepted')
      .order(created_at: :desc)
    render json: InvitationSerializer.render(invitations)
  end

  def create
    authorize Invitation, :create?

    invitation = Invitation.new(invitation_params)
    invitation.inviter = current_user
    invitation.client = current_client

    if invitation.save
      render json: InvitationSerializer.render(invitation), status: :created
    else
      render json: { error: invitation.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def resend
    authorize @invitation, :resend?

    result = @invitation&.resend
    if result && result[:success]
      render json: InvitationSerializer.render(@invitation), status: :ok
    else
      render json: { error: 'Cannot resend this invitation' }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @invitation, :destroy?

    @invitation.destroy
    head :no_content
  end

  private
    def invitation_params
      params.require(:invitation).permit(:email, :role)
    end

    def set_invitation
      @invitation = current_client.invitations.find(params[:id])
    end
end
