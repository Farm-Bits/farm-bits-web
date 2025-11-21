class UserArea::DashboardController < UserArea::ApplicationController
  def show
    authorize :dashboard, :show?

    render inertia: 'UserArea/Dashboard'
  end
end
