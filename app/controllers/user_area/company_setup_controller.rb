class UserArea::CompanySetupController < UserArea::ApplicationController
  skip_before_action :ensure_user_has_company_access, only: [:new, :create]

  def new
    authorize Company, :new?

    errors = current_user.active_companies_connections.any? ? nil : ['You do not have access to any company. Create one now.']
    render inertia: 'UserArea/CompanySetupForm', props: {
      errors: errors
    }
  end

  def edit
    authorize current_company, :edit?

    render inertia: 'UserArea/Settings/index'
  end

  def create
    authorize Company, :create?

    company = Company.new(company_params)
    company.company_users_attributes = [{ user: current_user, role: Roleable::ROLE_IDS[:admin] }]

    if company.save
      if current_user_session.present?
        current_user_session.update_column(:current_company_id, company.id)
      end
      redirect_to root_path
    else
      render inertia: 'UserArea/CompanySetupForm', props: {
        errors: company.errors.full_messages
      }
    end
  end

  def update
    authorize current_company, :update?

    if current_company.update(company_params)
      redirect_to user_company_setup_edit_path(company_id: current_company.id)
    else
      render inertia: 'UserArea/Settings/index', props: {
        errors: current_company.errors.full_messages
      }
    end
  end

  def destroy
    authorize current_company, :destroy?

    begin
      current_company.destroy!
      redirect_to root_path
    rescue => e
      render inertia: 'UserArea/Settings/index', props: {
        errors: [e.message]
      }
    end
  end

  private
    def company_params
      params.require(:company).permit(:name, :color, :require_2fa, site_attributes: [:country, :city, :latitude, :longitude])
    end
end
