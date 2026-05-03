class UserArea::AlertRulesController < UserArea::ApplicationController
  before_action :set_alert_rule, only: [:edit, :update, :destroy]

  def index
    authorize :alert_rule, :index?

    rules = policy_scope(AlertRule)
      .includes(measurement_point: [:site, :register_template])
      .order(:name)

    render inertia: 'UserArea/AlertRules/index', props: {
      alertRules: AlertRuleSerializer.render_as_json(rules, view: :with_measurement_point)
    }
  end

  def new
    authorize :alert_rule, :new?

    render inertia: 'UserArea/AlertRules/new', props: {
      measurementPoints: available_measurement_points
    }
  end

  def create
    authorize :alert_rule, :create?

    rule = AlertRule.new(alert_rule_params)

    if rule.save
      render json: { alertRule: AlertRuleSerializer.render_as_json(rule, view: :with_measurement_point) }, status: :created
    else
      render json: { error: rule.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def edit
    authorize @alert_rule

    render inertia: 'UserArea/AlertRules/edit', props: {
      alertRule:         AlertRuleSerializer.render_as_json(@alert_rule, view: :with_measurement_point),
      measurementPoints: available_measurement_points
    }
  end

  def update
    authorize @alert_rule

    if @alert_rule.update(alert_rule_params)
      render json: { alertRule: AlertRuleSerializer.render_as_json(@alert_rule, view: :with_measurement_point) }
    else
      render json: { error: @alert_rule.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @alert_rule
    @alert_rule.destroy
    render json: {}, status: :ok
  end

  private
    def set_alert_rule
      @alert_rule = policy_scope(AlertRule).find(params[:id])
    end

    def alert_rule_params
      params.require(:alert_rule).permit(
        :name, :severity, :condition_type, :direction,
        :threshold_value, :inactivity_seconds, :min_duration_seconds,
        :active, :measurement_point_id
      )
    end

    def available_measurement_points
      mps = policy_scope(MeasurementPoint)
        .joins(:register_template)
        .where(register_templates: { user_visibility: 'visible' })
        .where.not(measurement_subtype_id: nil)
        .includes(:register_template, :segment)
        .order(:name)

      mps.map do |mp|
        {
          id:           mp.id,
          name:         mp.name,
          segment_name: mp.segment&.name,
          unit:         mp.effective_unit,
          value_format: mp.register_template.value_format
        }
      end
    end
end
