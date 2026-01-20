class UserArea::ClientUsersController < UserArea::ApplicationController
  before_action :set_client_user, only: [:update, :destroy]

  def index
    authorize ClientUser, :index?

    client_users = policy_scope(ClientUser).includes(:user, :client_user_sites)
    render json: ClientUserSerializer.render_as_json(client_users, context: pundit_user), status: :ok
  end

  def update
    authorize @client_user, :update?

    ActiveRecord::Base.transaction do
      @client_user.update!(client_user_params)

      if @client_user.admin?
        clear_site_assignments
      elsif client_user_site_params[:site_ids].present?
        update_site_assignments(client_user_site_params[:site_ids])
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
      params.require(:client_user).permit(:role)
    end

    def client_user_site_params
      params.require(:client_user).permit(site_ids: [])
    end

    def set_client_user
      @client_user = policy_scope(ClientUser).find(params[:id])
    end

    def update_site_assignments(requested_site_ids)
      requested_site_ids = requested_site_ids.map(&:to_i)
      modifiable_site_ids = policy_scope(Site).pluck(:id)
      sites_to_assign = requested_site_ids & modifiable_site_ids

      ClientUserSite.where(
        client_user: @client_user,
        site_id: modifiable_site_ids
      ).where.not(site_id: sites_to_assign).destroy_all

      sites_to_assign.each do |site_id|
        ClientUserSite.find_or_create_by!(
          client_user: @client_user,
          site_id: site_id
        )
      end
    end

    def clear_site_assignments
      ClientUserSite.where(client_user: @client_user).destroy_all
    end
end
