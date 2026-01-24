class UserArea::CompanyUsersController < UserArea::ApplicationController
  before_action :set_company_user, only: [:update, :destroy]

  def index
    authorize CompanyUser, :index?

    company_users = policy_scope(CompanyUser).includes(:user, :company_user_sites)
    render json: CompanyUserSerializer.render_as_json(company_users, context: pundit_user), status: :ok
  end

  def update
    authorize @company_user, :update?

    ActiveRecord::Base.transaction do
      @company_user.update!(company_user_params)

      if @company_user.admin?
        clear_site_assignments
      elsif company_user_site_params[:site_ids].present?
        update_site_assignments(company_user_site_params[:site_ids])
      end
    end

    render json: CompanyUserSerializer.render_as_json(@company_user.reload, context: pundit_user), status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      error: e.record.errors.full_messages.to_sentence
    }, status: :unprocessable_entity
  end

  def destroy
    authorize @company_user, :destroy?

    begin
      @company_user.destroy!
      head :no_content
    rescue => e
      render json: { error: @company_user.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  private
    def company_user_params
      params.require(:company_user).permit(:role)
    end

    def company_user_site_params
      params.require(:company_user).permit(site_ids: [])
    end

    def set_company_user
      @company_user = policy_scope(CompanyUser).find(params[:id])
    end

    def update_site_assignments(requested_site_ids)
      requested_site_ids = requested_site_ids.map(&:to_i)
      modifiable_site_ids = policy_scope(Site).pluck(:id)
      sites_to_assign = requested_site_ids & modifiable_site_ids

      CompanyUserSite.where(
        company_user: @company_user,
        site_id: modifiable_site_ids
      ).where.not(site_id: sites_to_assign).destroy_all

      sites_to_assign.each do |site_id|
        CompanyUserSite.find_or_create_by!(
          company_user: @company_user,
          site_id: site_id
        )
      end
    end

    def clear_site_assignments
      CompanyUserSite.where(company_user: @company_user).destroy_all
    end
end
