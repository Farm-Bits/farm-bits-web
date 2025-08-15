class UserArea::DashboardController < UserArea::ApplicationController
  def index
    render inertia: 'UserArea/Dashboard', props: {
    #   stats: user_stats,
    #   recentActivity: recent_activity
    }
  end
end
