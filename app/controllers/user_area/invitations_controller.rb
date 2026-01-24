class UserArea::InvitationsController < UserArea::ApplicationController
  # before_action :set_invitation, only: [:update, :resend, :destroy]
  before_action :set_invitation, only: [:resend, :destroy]

  def index
    authorize Invitation, :index?

    invitations = policy_scope(Invitation)
      .where.not(status: 'accepted')
      .includes(:invitation_sites)
    render json: InvitationSerializer.render_as_json(invitations, context: pundit_user), status: :ok
  end

  def create
    authorize Invitation, :create?

    invitation = Invitation.new(invitation_params)
    invitation.inviter = current_user
    invitation.company = current_company

    if !invitation.admin? && invitation_site_params[:site_ids].present?
      build_site_assignments(invitation, invitation_site_params[:site_ids])
    end

    if invitation.save
      render json: InvitationSerializer.render_as_json(invitation, context: pundit_user), status: :created
    else
      render json: { error: invitation.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # def update
  #   authorize @invitation, :update?

  #   ActiveRecord::Base.transaction do
  #     @invitation.update!(invitation_params)

  #     if @invitation.admin?
  #       clear_site_assignments
  #     elsif invitation_site_params[:site_ids].present?
  #       update_site_assignments(invitation_site_params[:site_ids])
  #     end
  #   end

  #   render json: InvitationSerializer.render_as_json(@invitation.reload, context: pundit_user), status: :ok
  # rescue ActiveRecord::RecordInvalid => e
  #   render json: {
  #     error: e.record.errors.full_messages.to_sentence
  #   }, status: :unprocessable_entity
  # end

  def resend
    authorize @invitation, :resend?

    result = @invitation&.resend
    if result && result[:success]
      render json: InvitationSerializer.render_as_json(@invitation, context: pundit_user), status: :ok
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

    def invitation_site_params
      params.require(:invitation).permit(site_ids: [])
    end

    def set_invitation
      @invitation = policy_scope(Invitation).find(params[:id])
    end

    def build_site_assignments(invitation, requested_site_ids)
      requested_site_ids = requested_site_ids.map(&:to_i)
      modifiable_site_ids = policy_scope(Site).pluck(:id)
      sites_to_assign = requested_site_ids & modifiable_site_ids

      sites_to_assign.each do |site_id|
        invitation.invitation_sites.build(site_id: site_id)
      end
    end

    # def update_site_assignments(requested_site_ids)
    #   requested_site_ids = requested_site_ids.map(&:to_i)
    #   modifiable_site_ids = policy_scope(Site).pluck(:id)
    #   sites_to_assign = requested_site_ids & modifiable_site_ids

    #   InvitationSite.where(
    #     invitation: @invitation,
    #     site_id: modifiable_site_ids
    #   ).where.not(site_id: sites_to_assign).destroy_all

    #   sites_to_assign.each do |site_id|
    #     InvitationSite.find_or_create_by!(
    #       invitation: @invitation,
    #       site_id: site_id
    #     )
    #   end
    # end

    def clear_site_assignments
      InvitationSite.where(invitation: @invitation).destroy_all
    end
end
