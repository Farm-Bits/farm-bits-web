class UserArea::AnalyticsController < UserArea::ApplicationController
  def show
    authorize :analytics, :show?

    measurement_points = AnalyticsQueryService.eligible_scope(current_site)
      .includes(:register_template, :measurement_subtype, :segment, :plc)
    segments = current_site.segments.order(:name)
    measurement_subtypes = MeasurementSubtype
      .joins(:measurement_type)
      .where(id: measurement_points.select(:measurement_subtype_id).distinct)
      .order('measurement_types.position, measurement_subtypes.position')
      .includes(:measurement_type)

    render inertia: 'UserArea/Analytics', props: {
      segments: SegmentSerializer.render_as_hash(segments),
      measurement_points: MeasurementPointSerializer.render_as_hash(measurement_points, view: :with_details),
      measurement_subtypes: MeasurementSubtypeSerializer.render_as_hash(measurement_subtypes)
    }
  end

  def hourly
    authorize :analytics, :hourly?

    mp_ids = validated_measurement_point_ids
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])

    if end_date < start_date
      render json: { error: 'end_date must be after start_date' }, status: :unprocessable_entity
      return
    end

    result = AnalyticsQueryService.hourly(mp_ids, start_date, end_date)

    aggregations_json = result[:aggregations].transform_values do |records|
      HourlyAggregationSerializer.render_as_hash(records)
    end

    render json: {
      aggregations: aggregations_json,
      summary: result[:summary]
    }
  end

  def raw
    authorize :analytics, :raw?

    mp_ids = validated_measurement_point_ids
    start_time = Time.zone.parse(params[:start_time])
    end_time = Time.zone.parse(params[:end_time])

    # Enforce 24-hour max range
    if (end_time - start_time) > 24.hours
      render json: { error: 'Raw data range limited to 24 hours' }, status: :unprocessable_entity
      return
    end

    result = AnalyticsQueryService.raw(mp_ids, start_time, end_time)

    raw_json = result[:raw_values].transform_values do |records|
      RawValueSerializer.render_as_hash(records)
    end

    render json: { raw_values: raw_json }
  end

  private
    def validated_measurement_point_ids
      requested_ids = Array(params[:measurement_point_ids]).map(&:to_i)
      eligible_ids = AnalyticsQueryService.eligible_scope(current_site).where(id: requested_ids).pluck(:id)

      if eligible_ids.empty?
        render json: { error: 'No valid measurement points found' }, status: :unprocessable_entity
        return []
      end

      eligible_ids
    end
end
