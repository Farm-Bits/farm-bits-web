# Behavior: When an IO is deactivated, clear all sensor trigger
# conditions that referenced it across all DOs on this PLC.
#
# Register groups:
#   om_sensor_cond_* - Each condition has source_type and source_io_number.
#                      source_type maps to communication_type:
#                        0=disabled, 1=AI, 2=DI, 3=DO, 4=AO
#                      source_io_number is the interface io_number (1-based).
#
# When AI3 is deactivated:
#   Find all conditions where source_type=1 AND source_io_number=3
#   Write 0 to both source_type and source_io_number on those conditions
#
module PlcBehaviors::Concerns::SensorCascade
  extend ActiveSupport::Concern

  def cascade_sensor_deactivation!(communication_type, io_number)
    type_value = source_type_for(communication_type)
    if !type_value.present?
      return
    end

    # Find all sensor condition groups on this PLC that reference this IO.
    # We need to find pairs where source_type matches AND source_io_number matches.
    #
    # Strategy: find source_type measurement points with the matching value,
    # then check the sibling source_io_number in the same group.
    source_type_points = plc.measurement_points
      .joins(:register_template)
      .where(register_templates: {
        category: 'operation_mode_configuration',
        group_role: 'source_type'
      })
      .where('register_templates.group_name LIKE ?', 'om_sensor_cond_%')
      .where(last_decoded_value: type_value)
      .includes(:register_template)
    if source_type_points.empty?
      return
    end

    writes = []

    source_type_points.each do |type_mp|
      group_name = type_mp.register_template.group_name
      # Find the sibling source_io_number in the same group
      io_number_mp = plc.measurement_points
        .joins(:register_template)
        .where(register_templates: {
          group_name: group_name,
          group_role: 'source_io_number'
        })
        .first
      if !io_number_mp.present?
        next
      end

      # Clear both source_type and source_io_number
      writes << { measurement_point: type_mp, value: 0 }
      writes << { measurement_point: io_number_mp, value: 0 }
    end

    if writes.empty?
      return
    end

    bulk_write!(writes, source: 'deactivation_cascade')
  end
end
