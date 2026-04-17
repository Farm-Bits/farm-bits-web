class UserArea::MeasurementPointsController < UserArea::ApplicationController
  before_action :set_measurement_point_for_update, only: [:update]
  before_action :set_measurement_point_for_write, only: [:write]
  before_action :set_measurement_point_for_om_config, only: [:operation_mode_config]

  def update
    authorize @measurement_point, :update?

    ActiveRecord::Base.transaction do
      if params[:measurement_point].present?
        if !@measurement_point.update(measurement_point_params)
          raise ActiveRecord::Rollback
        end
      end

      if params[:configuration_updates].present?
        process_configuration_updates!
      end
    end

    if @measurement_point.errors.empty?
      siblings = @measurement_point.sibling_measurement_points
        .includes(:register_template, :measurement_subtype)

      render json: {
        measurement_point: MeasurementPointSerializer.render_as_json(@measurement_point.reload),
        sibling_measurement_points: MeasurementPointSerializer.render_as_json(siblings)
      }, status: :ok
    else
      render json: { error: @measurement_point.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def write
    authorize @measurement_point, :write?

    begin
      context = PlcWriteContext.user_action(current_user)
      service = PlcWriteService.new(@measurement_point)
      service.write!(params[:value], context: context)

      render json: MeasurementPointSerializer.render_as_json(@measurement_point.reload), status: :ok
    rescue PlcWriteService::ValidationError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue PlcWriteService::ConnectionError => e
      render json: { error: e.message }, status: :service_unavailable
    rescue PlcWriteService::WriteError => e
      Rails.logger.error "MeasurementPoint write error: #{e.message}"
      render json: { error: 'Failed to write value to PLC' }, status: :internal_server_error
    end
  end

  def operation_mode_config
    authorize @measurement_point, :operation_mode_config?

    interface = @measurement_point.register_template
      .interface_register_mappings
      .first&.interface

    if !interface
      render json: { error: 'Measurement point is not associated with an interface' }, status: :unprocessable_entity
      return
    end

    plc = @measurement_point.plc

    # Load all OM registers (status + configuration) for this interface
    om_measurement_points = plc.measurement_points
      .joins(:register_template)
      .joins(
        "INNER JOIN interface_register_mappings irm " \
        "ON irm.register_template_id = register_templates.id"
      )
      .where("irm.interface_id = ?", interface.id)
      .where(register_templates: {
        category: ['operation_mode_status', 'operation_mode_configuration'],
        user_visibility: 'visible'
      })
      .includes(:register_template, plc: [:gateway])
      .order('register_templates.position')

    register_mappings = om_measurement_points.map do |mp|
      {
        register_template: RegisterTemplateSerializer.render_as_json(mp.register_template),
        measurement_point: MeasurementPointSerializer.render_as_json(mp),
        position: mp.register_template.position
      }
    end.sort_by { |rm| rm[:position] }

    # Pre-resolved group labels from GroupSchemas
    group_labels = om_measurement_points
      .map { |mp| mp.register_template.group_name }
      .compact
      .uniq
      .each_with_object({}) do |name, hash|
        label = PlcBehaviors::GroupSchemas.label_for(name)
        if label.present?
          hash[name] = label
        end
      end

    render json: {
      register_mappings: register_mappings,
      group_labels: group_labels,
      available_sources: build_available_sources(plc)
    }, status: :ok
  end

  private
    # For update: the anchor must be a data-category register on an interface.
    # This ensures we can find sibling config registers on the same interface.
    def set_measurement_point_for_update
      @measurement_point = policy_scope(MeasurementPoint)
        .includes(:measurement_subtype, :register_template, :segment, plc: [:gateway])
        .find(params[:id])

      if @measurement_point.register_template.interface_register_mappings.empty?
        render json: { error: 'Measurement point is not associated with an interface' }, status: :unprocessable_entity
        return
      end

      if !@measurement_point.register_template.category.in?(MeasurementSubtype::DATA_CATEGORIES)
        render json: { error: 'Can not update configuration directly from this measurement point' }, status: :unprocessable_entity
        return
      end
    end

    # For write: any writable, visible MP the user has access to.
    # Used for immediate actions (manual commands, emergency stop, etc.)
    def set_measurement_point_for_write
      @measurement_point = policy_scope(MeasurementPoint)
        .includes(:register_template, plc: [:gateway])
        .find(params[:id])

      if @measurement_point.register_template.read_only?
        render json: { error: 'Register is read-only' }, status: :unprocessable_entity
        return
      end
    end

    def set_measurement_point_for_om_config
      @measurement_point = policy_scope(MeasurementPoint)
        .includes(
          :register_template,
          register_template: :interface_register_mappings,
          plc: [:gateway, :plc_version]
        )
        .find(params[:id])

      if @measurement_point.register_template.interface_register_mappings.empty?
        render json: { error: 'Measurement point is not associated with an interface' }, status: :unprocessable_entity
        return
      end

      if !@measurement_point.register_template.category.in?(MeasurementSubtype::DATA_CATEGORIES)
        render json: { error: 'Must use a data-category measurement point as anchor' }, status: :unprocessable_entity
        return
      end
    end

    def measurement_point_params
      params.require(:measurement_point).permit(
        :name,
        :description,
        :unit_override,
        :chart_type_override,
        :color_override,
        # :data_collection_enabled,
        # :polling_interval_seconds,
        :factor_override,
        :offset_override,
        :alarm_low,
        :alarm_high,
        :warning_low,
        :warning_high,
        :active,
        :measurement_subtype_id,
        :segment_id
      )
    end

    def configuration_updates_params
      if !params[:configuration_updates].is_a?(Array)
        return []
      end

      params[:configuration_updates].map do |update|
        update.permit(:measurement_point_id, :value)
      end
    end

    # ── Configuration Updates ─────────────────────────────

    WRITABLE_CONFIG_CATEGORIES = %w[
      interface_configuration
      operation_mode_configuration
    ].freeze

    def process_configuration_updates!
      updates = configuration_updates_params
      if updates.empty?
        return
      end

      # Load allowed config points for this interface
      allowed_config_points = @measurement_point.sibling_measurement_points
        .joins(:register_template)
        .where(register_templates: { user_visibility: 'visible', category: WRITABLE_CONFIG_CATEGORIES })
        .where(register_templates: { read_only: false })
        .includes(:register_template, plc: [:gateway])
        .index_by(&:id)

      # Validate all measurement point IDs are allowed
      updates.each do |update|
        if !allowed_config_points.key?(update[:measurement_point_id].to_i)
          @measurement_point.errors.add(:base, "Invalid configuration: #{update[:measurement_point_id]}")
          raise ActiveRecord::Rollback
        end
      end

      # Build pending values for group validation
      pending_values = updates.each_with_object({}) do |update, hash|
        config_point = allowed_config_points[update[:measurement_point_id].to_i]
        hash[config_point.register_template_id] = update[:value]
      end

      validator = RegisterGroupValidator.new(allowed_config_points.values, pending_values)
      if !validator.valid?
        @measurement_point.errors.add(:base, validator.errors.join('; '))
        raise ActiveRecord::Rollback
      end

      # Build payload for the write service
      config_points_with_values = updates.map do |update|
        {
          measurement_point: allowed_config_points[update[:measurement_point_id].to_i],
          value: update[:value]
        }
      end

      context = PlcWriteContext.user_action(current_user)
      service = PlcWriteService.new(@measurement_point)
      service.bulk_write!(config_points_with_values, context: context)
    rescue PlcWriteService::ValidationError => e
      @measurement_point.errors.add(:base, e.message)
      raise ActiveRecord::Rollback
    rescue PlcWriteService::ConnectionError => e
      @measurement_point.errors.add(:base, e.message)
      raise ActiveRecord::Rollback
    rescue PlcWriteService::WriteError => e
      Rails.logger.error "Configuration write error: #{e.message}"
      @measurement_point.errors.add(:base, e.message)
      raise ActiveRecord::Rollback
    end

    def build_available_sources(plc)
      data_mps = plc.measurement_points
        .joins(:register_template)
        .where(active: true)
        .where.not(measurement_subtype_id: nil)
        .where(register_templates: { category: MeasurementSubtype::DATA_CATEGORIES })
        .includes(
          :measurement_subtype,
          register_template: { interface_register_mappings: :interface }
        )

      mps_by_interface_id = Hash.new { |h, k| h[k] = [] }
      data_mps.each do |mp|
        mp.register_template.interface_register_mappings.each do |irm|
          mps_by_interface_id[irm.interface_id] << mp
        end
      end

      sources = []
      plc.plc_version.interfaces.each do |iface|
        source_type = PlcBehaviors::Base::SOURCE_TYPE_MAP[iface.communication_type]
        if !source_type
          next
        end

        mps_by_interface_id[iface.id].each do |mp|
          sources << {
            label: "#{iface.name}: #{mp.name}",
            communication_type: iface.communication_type,
            io_number: iface.io_number,
            source_type: source_type,
            effective_factor: (mp.factor_override || mp.register_template.factor)&.to_f,
            effective_offset: (mp.offset_override || mp.register_template.offset)&.to_f,
            effective_unit: mp.effective_unit,
            last_value: mp.scaled_last_decoded_value
          }
        end
      end

      sources
    end
end
