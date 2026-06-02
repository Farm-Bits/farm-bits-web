class Api::Mobile::V1::AlertsController < Api::Mobile::V1::BaseController
  DEFAULT_PER_PAGE = 50
  MAX_PER_PAGE = 100
  VALID_STATUS = %w[active past all].freeze

  def index
    authorize :alert, :index?

    status = params[:status].presence || 'all'
    if !VALID_STATUS.include?(status)
      render json: { error: 'invalid_status' }, status: :bad_request
      return
    end

    scope = policy_scope(Alert)
      .ordered
      .includes(:alert_rule, :measurement_point, :site)

    case status
    when 'active'
      scope = scope.open
    when 'past'
      scope = scope.closed
    end

    if params[:segment_id].present?
      scope = scope.joins(:measurement_point)
        .where(measurement_points: { segment_id: params[:segment_id].to_i })
    end

    page = [params[:page].to_i, 1].max
    per_page = (params[:per_page].presence || DEFAULT_PER_PAGE).to_i.clamp(1, MAX_PER_PAGE)
    offset = (page - 1) * per_page

    # Fetch one extra to know if there's a next page without a COUNT query.
    rows = scope.offset(offset).limit(per_page + 1).to_a
    has_more = rows.size > per_page
    alerts = rows.first(per_page)

    render json: {
      alerts: AlertSerializer.render_as_hash(alerts),
      pagination: {
        page: page,
        per_page: per_page,
        has_more: has_more
      }
    }
  end

  def show
    authorize :alert, :show?

    alert = policy_scope(Alert).find(params[:id])

    render json: {
      alert: AlertSerializer.render_as_hash(alert)
    }
  end
end
