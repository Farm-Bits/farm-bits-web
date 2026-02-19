class UserArea::LiveController < UserArea::ApplicationController
  def show
    authorize :live, :show?

    measurement_points = AnalyticsQueryService.eligible_scope(current_site)
      .includes(:register_template, :measurement_subtype, :segment, :plc)
    segments = current_site.segments.order(:name)
    measurement_subtypes = MeasurementSubtype
      .joins(:measurement_type)
      .where(id: measurement_points.select(:measurement_subtype_id).distinct)
      .order('measurement_types.position, measurement_subtypes.position')
      .includes(:measurement_type)

    render inertia: 'UserArea/Live/index', props: {
      segments: SegmentSerializer.render_as_hash(segments),
      measurement_points: MeasurementPointSerializer.render_as_hash(measurement_points, view: :with_details),
      measurement_subtypes: MeasurementSubtypeSerializer.render_as_hash(measurement_subtypes)
    }
  end

  def poll
    authorize :live, :poll?

    measurement_points = AnalyticsQueryService.eligible_scope(current_site)

    data = measurement_points.map do |mp|
      {
        id: mp.id,
        last_value: mp.last_decoded_value,
        last_value_at: mp.last_decoded_value_at,
        alarm_state: mp.alarm_state
      }
    end

    render json: { measurement_points: data }
  end
end
