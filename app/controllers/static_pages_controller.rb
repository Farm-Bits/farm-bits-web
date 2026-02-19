class StaticPagesController < ApplicationController
  def home
    redirect_params = params.permit(:company_id)

    if current_user
      return redirect_to user_root_path(redirect_params)
    elsif current_admin_user
      return redirect_to supervisor_root_path(redirect_params)
    end

    render inertia: 'StaticPages/Home'
  end

  def privacy_policy
    render inertia: 'StaticPages/PrivacyPolicy'
  end
end
