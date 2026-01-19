class UserArea::ClientUsersController < UserArea::ApplicationController
  before_action :set_client_user, only: [:update, :destroy]

  def index
    authorize ClientUser, :index?

    client_users = policy_scope(ClientUser)
    render json: ClientUserSerializer.render_as_json(client_users, context: pundit_user), status: :ok
  end

  def update
    authorize @client_user, :update?

    if @client_user.update(client_user_params)
      render json: ClientUserSerializer.render_as_json(@client_user, context: pundit_user), status: :ok
    else
      render json: { error: @client_user.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def update
    authorize @client_user, :update?

    ActiveRecord::Base.transaction do
      @client_user.update!(client_user_params)

      if !@client_user.admin? && client_site_user_params[:site_ids].present?
        update_site_assignments(client_site_user_params[:site_ids])
      end
    end

    render json: ClientUserSerializer.render_as_json(@client_user.reload, context: pundit_user), status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      error: e.record.errors.full_messages.to_sentence
    }, status: :unprocessable_entity
  end

  def destroy
    authorize @client_user, :destroy?

    begin
      @client_user.destroy!
      head :no_content
    rescue => e
      render json: { error: @client_user.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  private
    def client_user_params
      permitted = params.require(:client_user).permit(:user_id, :role)
      if permitted[:user_id].blank?
        raise ActionController::ParameterMissing, :user_id
      end
      permitted
    end

    def client_site_user_params
      params.require(:client_user).permit(site_ids: [])
    end

    def set_client_user
      @client_user = policy_scope(ClientUser).find_by(id: params[:id])
    end

    def update_site_assignments(requested_site_ids)
      requested_site_ids = requested_site_ids.map(&:to_i)
      modifiable_site_ids = SitePolicy::Scope.new(pundit_user, Site).resolve.pluck(:id)
      sites_to_assign = requested_site_ids & modifiable_site_ids
      SiteUser.where(
        user: @client_user.user,
        site_id: modifiable_site_ids
      ).where.not(site_id: sites_to_assign).destroy_all

      sites_to_assign.each do |site_id|
        SiteUser.find_or_create_by!(
          user: @client_user.user,
          site_id: site_id
        )
      end
    end
end
