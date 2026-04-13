# When source_io changes (or is set for the first time), we resolve the
# source interface's active measurement point and propagate its scaling.
# When source_io is cleared (set to 0), we clear the overrides.
#
# Register groups:
#   om_sensor_cond_* - Each condition has:
#     source_type      - communication_type as integer (1=AI, 2=DI, 3=DO, 4=AO)
#     source_io_number - interface io_number (1-based)
#     threshold        - comparison value (needs source IO scaling)
#     hysteresis       - deadband value (needs source IO scaling)
#
module PlcBehaviors::Concerns::SensorConditionScaling
  extend ActiveSupport::Concern

  SCALING_TARGET_ROLES = %w[threshold hysteresis].freeze

  # Pre-write transform: called by PlcWriteService before reverse_scaled encoding.
  #
  # Scans the batch for source_type/source_io_number changes in om_sensor_cond_*
  # groups, resolves the source IO's scaling, and patches threshold/hysteresis MPs.
  #
  # @param entries [Array<Hash>] array of { measurement_point:, value: }
  # @return [Array<Hash>] the same array (MPs mutated in-place with updated overrides)
  def pre_write_transforms(entries)
    entries = super(entries)

    affected_groups = detect_source_changes(entries)
    if affected_groups.empty?
      return entries
    end

    affected_groups.each do |group_name, source_info|
      propagate_scaling_for_group(group_name, source_info, entries)
    end

    entries
  end

  private
    # Detect which om_sensor_cond_* groups have source_type or source_io_number
    # in the current batch. Returns a hash:
    #   { 'om_sensor_cond_1' => { source_type: 1, source_io_number: 3 } }
    #
    # Values come from the batch (pending write) when present, falling back
    # to the MP's current last_decoded_value.
    def detect_source_changes(entries)
      # Index batch entries by group_name and group_role for quick lookup
      batch_index = {}
      entries.each do |entry|
        mp = entry[:measurement_point]
        rt = mp.register_template
        if !rt.group_name&.start_with?('om_sensor_cond_')
          next
        end

        batch_index[rt.group_name] ||= {}
        batch_index[rt.group_name][rt.group_role] = entry
      end

      affected = {}

      batch_index.each do |group_name, roles|
        if !roles.key?('source_type') && !roles.key?('source_io_number')
          next
        end

        # Resolve final values: prefer batch value, fall back to current stored value
        source_type = resolve_value(roles, 'source_type', group_name)
        source_io_number = resolve_value(roles, 'source_io_number', group_name)

        affected[group_name] = {
          source_type: source_type.to_i,
          source_io_number: source_io_number.to_i
        }
      end

      affected
    end

    # Get the value for a role: from batch if present, otherwise from the
    # existing MP's last_decoded_value.
    def resolve_value(batch_roles, role, group_name)
      if batch_roles.key?(role)
        return batch_roles[role][:value]
      end

      # Not in batch — read current stored value
      mp = plc.measurement_points
        .joins(:register_template)
        .where(register_templates: { group_name: group_name, group_role: role })
        .first

      mp&.last_decoded_value.to_i
    end

    # Propagate scaling from the source IO to threshold/hysteresis MPs.
    def propagate_scaling_for_group(group_name, source_info, entries)
      factor, offset = resolve_source_scaling(
        source_info[:source_type],
        source_info[:source_io_number]
      )

      # Find threshold/hysteresis MPs — either in the batch or from DB
      SCALING_TARGET_ROLES.each do |role|
        mp = find_target_mp(group_name, role, entries)
        if !mp
          next
        end

        apply_scaling_overrides(mp, factor, offset)
      end
    end

    # Resolve the source IO's effective factor and offset.
    # Returns [factor, offset]. Returns [1.0, 0.0] (identity) if source is
    # disabled (type=0) or not found.
    def resolve_source_scaling(source_type, source_io_number)
      if source_type == 0 || source_io_number == 0
        return [1.0, 0.0]
      end

      communication_type = PlcBehaviors::Base::SOURCE_TYPE_MAP.key(source_type)
      if !communication_type
        return [1.0, 0.0]
      end

      # Find the active data-category measurement point on the source interface
      source_mp = plc.measurement_points
        .joins(register_template: { interface_register_mappings: :interface })
        .where(active: true)
        .where(register_templates: { category: MeasurementSubtype::DATA_CATEGORIES })
        .where(interfaces: {
          communication_type: communication_type,
          io_number: source_io_number
        })
        .first

      if !source_mp
        return [1.0, 0.0]
      end

      [source_mp.effective_factor, source_mp.effective_offset]
    end

    # Find the target MP for a role: first check the batch, then query DB.
    def find_target_mp(group_name, role, entries)
      # Check if it's already in the batch
      entries.each do |entry|
        rt = entry[:measurement_point].register_template
        if rt.group_name == group_name && rt.group_role == role
          return entry[:measurement_point]
        end
      end

      # Not in batch — load from DB (needed so future reads decode correctly)
      plc.measurement_points
        .joins(:register_template)
        .where(register_templates: { group_name: group_name, group_role: role })
        .first
    end

    # Persist factor_override and offset_override on the MP.
    # Uses update_columns for efficiency (no callbacks, no timestamps).
    # Also reloads the in-memory attributes so reverse_scaled uses the new values.
    def apply_scaling_overrides(mp, factor, offset)
      mp.update_columns(
        factor_override: factor,
        offset_override: offset
      )

      # Reload the override attributes so reverse_scaled() in the same
      # request uses the updated values.
      mp.factor_override = factor
      mp.offset_override = offset
    end
end
