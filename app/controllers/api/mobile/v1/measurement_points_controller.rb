class Api::Mobile::V1::MeasurementPointsController < Api::Mobile::V1::BaseController
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
        process_configuration_updates_for_anchor!
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
      context = ModbusWriteContext.user_action(current_user)
      ModbusWriteService.write!(@measurement_point, params[:value], context: context)

      render json: MeasurementPointSerializer.render_as_json(@measurement_point.reload), status: :ok
    rescue ModbusWriteService::ValidationError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue ModbusWriteService::ConnectionError => e
      render json: { error: e.message }, status: :service_unavailable
    rescue ModbusWriteService::WriteError => e
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
        label = ModbusBehaviors::GroupSchemas.label_for(name)
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

  def bulk_write
    updates = bulk_write_updates_params
    if updates.empty?
      render json: { error: 'No configuration updates provided' }, status: :unprocessable_entity
      return
    end

    mp_ids = updates.map { |u| u[:measurement_point_id].to_i }.uniq

    allowed_points = policy_scope(MeasurementPoint)
      .where(id: mp_ids)
      .joins(:register_template)
      .where(register_templates: {
        user_visibility: 'visible',
        category: ConfigurationUpdatesWriter::WRITABLE_CONFIG_CATEGORIES,
        read_only: false
      })
      .includes(:register_template, plc: [:gateway], modbus_device: [:gateway, plc: [:gateway]])
      .index_by(&:id)

    if allowed_points.size != mp_ids.size
      render json: { error: 'One or more measurement points are not accessible or not writable' },
             status: :forbidden
      return
    end

    allowed_points.each_value { |mp| authorize mp, :write? }

    begin
      ConfigurationUpdatesWriter.new(
        allowed_points: allowed_points,
        updates:        updates,
        context:        ModbusWriteContext.user_action(current_user)
      ).call

      reloaded = MeasurementPoint
        .where(id: mp_ids)
        .includes(:register_template, :measurement_subtype)

      render json: {
        measurement_points: MeasurementPointSerializer.render_as_json(reloaded)
      }, status: :ok
    rescue ConfigurationUpdatesWriter::ValidationError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue ConfigurationUpdatesWriter::ConnectionError => e
      render json: { error: e.message }, status: :service_unavailable
    rescue ConfigurationUpdatesWriter::WriteError => e
      Rails.logger.error "Bulk write error: #{e.message}"
      render json: { error: 'Failed to write values' }, status: :internal_server_error
    end
  end

  private
    # The anchor must be a data-category register. When it sits on an interface
    # (PLC flow), its visible config siblings can be written alongside the
    # record update. When it has no interface (a Modbus device's live
    # register), only the record is updated — sibling_measurement_points
    # returns none, so the configuration_updates path is a safe no-op.
    def set_measurement_point_for_update
      @measurement_point = policy_scope(MeasurementPoint)
        .includes(
          :measurement_subtype, :register_template, :segment,
          plc: [:gateway], modbus_device: [:gateway]
        )
        .find(params[:id])

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
          plc: [:gateway, :modbus_firmware_version]
        )
        .find(params[:id])


      if @measurement_point.plc.nil?
        render json: { error: 'Operation mode config is only available on PLC measurement points' },
               status: :unprocessable_entity
        return
      end

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
        :factor_override,
        :offset_override,
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

    def process_configuration_updates_for_anchor!
      updates = configuration_updates_params
      if updates.empty?
        return
      end

      allowed_points = @measurement_point.sibling_measurement_points
        .joins(:register_template)
        .where(register_templates: {
          user_visibility: 'visible',
          category: ConfigurationUpdatesWriter::WRITABLE_CONFIG_CATEGORIES,
          read_only: false
        })
        .includes(:register_template, plc: [:gateway])
        .index_by(&:id)

      ConfigurationUpdatesWriter.new(
        allowed_points: allowed_points,
        updates:        updates,
        context:        ModbusWriteContext.user_action(current_user)
      ).call
    rescue ConfigurationUpdatesWriter::ValidationError, ConfigurationUpdatesWriter::ConnectionError => e
      @measurement_point.errors.add(:base, e.message)
      raise ActiveRecord::Rollback
    rescue ConfigurationUpdatesWriter::WriteError => e
      Rails.logger.error "Configuration write error: #{e.message}"
      @measurement_point.errors.add(:base, e.message)
      raise ActiveRecord::Rollback
    end

    def build_available_sources(plc)
      behavior = ModbusBehaviors.for(plc)

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
      plc.modbus_firmware_version.interfaces.each do |iface|
        source_type = behavior.source_type_for(iface.communication_type)
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

    def bulk_write_updates_params
      raw = params[:configuration_updates]
      if !raw.is_a?(Array)
        return []
      end

      raw.map { |update| update.permit(:measurement_point_id, :value) }
    end
end
