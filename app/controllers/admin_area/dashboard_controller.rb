class AdminArea::DashboardController < AdminArea::ApplicationController
  def show
    render inertia: 'AdminArea/Dashboard'
  end
end
