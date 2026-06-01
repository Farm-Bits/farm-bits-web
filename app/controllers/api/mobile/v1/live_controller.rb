class Api::Mobile::V1::LiveController < Api::Mobile::V1::BaseController
  def show
    authorize :live, :show?

    measurement_points = AnalyticsQueryService.eligible_scope(current_site)
      .includes(
        :segment,
        :plc,
        :modbus_device,
        measurement_subtype: [:measurement_type, :control_group],
        register_template: { interface_register_mappings: :interface }
      )

    measurement_subtypes = MeasurementSubtype
      .joins(:measurement_type)
      .where(id: measurement_points.select(:measurement_subtype_id).distinct)
      .order('measurement_types.position, measurement_subtypes.position')
      .includes(:measurement_type, :control_group)

    render json: {
      measurement_points: MeasurementPointSerializer.render_as_hash(measurement_points, view: :with_details_live),
      measurement_subtypes: MeasurementSubtypeSerializer.render_as_hash(measurement_subtypes)
    }
  end

  def poll
    authorize :live, :poll?

    measurement_points = AnalyticsQueryService.eligible_scope(current_site)
      .includes(:register_template, :measurement_subtype)

    render json: {
      measurement_points: MeasurementPointSerializer.render_as_hash(measurement_points, view: :live_poll)
    }
  end
end
