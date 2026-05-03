class UserArea::AlertsController < UserArea::ApplicationController
  def index
    authorize :alert, :index?

    alerts = policy_scope(Alert)
      .ordered
      .includes(:alert_rule, :measurement_point, :site)
      .limit(500)

    render inertia: 'UserArea/Alerts/index', props: {
      alerts: AlertSerializer.render_as_json(alerts)
    }
  end
end
