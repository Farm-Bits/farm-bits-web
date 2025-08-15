class AdminArea::DashboardController < AdminArea::ApplicationController
  def index
    render inertia: 'AdminArea/Dashboard', props: {
    #   stats: user_stats,
    #   recentActivity: recent_activity
    }
  end
end
