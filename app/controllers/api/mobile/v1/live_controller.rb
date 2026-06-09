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

    live_includes = [:plc, register_template: { interface_register_mappings: :interface }]
    interface_statuses = live_registers_scope(['interface_status'], includes: live_includes)
    om_statuses = live_registers_scope(['operation_mode_status'], includes: live_includes)
    om_configurations = live_registers_scope(['operation_mode_configuration'], includes: live_includes)
    om_group_labels = build_om_group_labels(om_statuses + om_configurations)

    measurement_subtypes = MeasurementSubtype
      .joins(:measurement_type)
      .where(id: measurement_points.select(:measurement_subtype_id).distinct)
      .order('measurement_types.position, measurement_subtypes.position')
      .includes(:measurement_type, :control_group)

    render json: {
      measurement_points: MeasurementPointSerializer.render_as_hash(measurement_points, view: :with_details_live),
      interface_statuses: MeasurementPointSerializer.render_as_hash(interface_statuses, view: :with_details),
      operation_mode_statuses: MeasurementPointSerializer.render_as_hash(om_statuses, view: :with_details),
      operation_mode_configurations: MeasurementPointSerializer.render_as_hash(om_configurations, view: :with_details),
      operation_mode_group_labels: om_group_labels,
      measurement_subtypes: MeasurementSubtypeSerializer.render_as_hash(measurement_subtypes)
    }
  end

  def poll
    authorize :live, :poll?

    measurement_points = AnalyticsQueryService.eligible_scope(current_site)
      .includes(:register_template, :measurement_subtype)

    interface_statuses = live_registers_scope(['interface_status'], includes: :register_template)
    om_statuses = live_registers_scope(['operation_mode_status'], includes: :register_template)

    render json: {
      measurement_points: MeasurementPointSerializer.render_as_hash(measurement_points, view: :live_poll),
      interface_statuses: MeasurementPointSerializer.render_as_hash(interface_statuses, view: :live_poll),
      operation_mode_statuses: MeasurementPointSerializer.render_as_hash(om_statuses, view: :live_poll)
    }
  end

  def poll_weather
    authorize :live, :poll?

    site_sun_data = SiteSunData.find_by(site: current_site, date: Date.current)

    render json: {
      weather_data: weather_data,
      sun_data: site_sun_data ? SiteSunDataSerializer.render_as_hash(site_sun_data) : nil
    }
  end

  private
    def live_registers_scope(categories, includes:)
      MeasurementPoint
        .joins(:register_template, plc: { gateway: { site: :company } })
        .where(active: true)
        .where(register_templates: { category: categories, user_visibility: 'visible' })
        .where(plcs: { active: true })
        .where(gateways: { active: true })
        .where(sites: { id: current_site.id })
        .where(companies: { active: true })
        .includes(includes)
    end

    def build_om_group_labels(measurement_points)
      measurement_points
        .map { |mp| mp.register_template.group_name }
        .compact
        .uniq
        .each_with_object({}) do |name, hash|
          label = ModbusBehaviors::GroupSchemas.label_for(name)
          if label.present?
            hash[name] = label
          end
        end
    end

    def weather_data
      weather_station_api_location = current_site.weather_station_api_location
      if weather_station_api_location.nil? || !weather_station_api_location.active?
        return nil
      end

      latest = WeatherStationApiAnalyticsQueryService.latest(weather_station_api_location.id)
      readings = latest.map do |reading|
        metric = reading.weather_station_api_metric
        {
          key: metric.key,
          label: metric.label,
          value: reading.scaled_value&.to_f,
          unit: metric.effective_unit,
          sample_time: reading.sample_time
        }
      end

      readings
    end
end
