class StaticPagesController < ApplicationController
  include ResolvesUserContext

  def home
    if current_user
      return redirect_to user_landing_path(company_id: params[:company_id])
    elsif current_admin_user
      # return redirect_to supervisor_root_path(params.permit(:company_id))
      return redirect_to admin_dashboard_path
    end

    render inertia: 'StaticPages/Home'
  end

  def privacy_policy
    render inertia: 'StaticPages/PrivacyPolicy'
  end
end
