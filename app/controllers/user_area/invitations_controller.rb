class UserArea::InvitationsController < UserArea::ApplicationController
  before_action :set_invitation, only: [:resend, :destroy]

  def index
    authorize Invitation, :index?

    invitations = policy_scope(Invitation)
      .where.not(status: 'accepted')
      .order(created_at: :desc)
    render json: InvitationSerializer.render_as_json(invitations)
  end

  def create
    authorize Invitation, :create?

    invitation = Invitation.new(invitation_params)
    invitation.inviter = current_user
    invitation.client = current_client

    if invitation.save
      render json: InvitationSerializer.render_as_json(invitation), status: :created
    else
      render json: { error: invitation.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def resend
    authorize @invitation, :resend?

    result = @invitation&.resend
    if result && result[:success]
      render json: InvitationSerializer.render_as_json(@invitation), status: :ok
    else
      render json: { error: 'Cannot resend this invitation' }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @invitation, :destroy?

    begin
      @invitation.destroy!
      head :no_content
    rescue => e
      render json: { error: @invitation.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  private
    def invitation_params
      params.require(:invitation).permit(:email, :role)
    end

    def set_invitation
      @invitation = policy_scope(Invitation).find_by(id: params[:id])
    end
end
