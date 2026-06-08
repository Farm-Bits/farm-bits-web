# Behavior profile for the FATEK FBs-20MC "Seedling Program v2.4.2",
# hosted as a PLC-relayed peripheral behind an Eliwell Free Advance V2 bridge.
#
# This class is the ONLY place that knows FATEK-specific program facts:
#   - how phase groups are named (program_{index}_phase_{phase})
#   - which shared-group registers belong to a program (humidity mode)
#   - how to trigger a host-side refresh of a program from the peripheral
#
# Everything generic (the programs builder, controller, and UI) reads
# register_template metadata and these declarations — never role names.
#
class ModbusBehaviors::FatekSeedlingV1 < ModbusBehaviors::Base
  # Phase groups are named "program_{index}_phase_{phase}", with a 0-based
  # program index and a 1-based phase number. The two captures feed the
  # generic builder's program/phase nesting.
  PROGRAM_GROUP_PATTERN = /\Aprogram_(\d+)_phase_(\d+)\z/

  def program_group_pattern
    PROGRAM_GROUP_PATTERN
  end

  def active_program_binding
    { group_name: 'system_status', group_role: 'program_select' }
  end

  # Per-program registers that live in the shared 'system_status' group (so
  # they share group_name and differ only by group_role). Bound: the humidity
  # control mode (operator-editable) and the program's "loaded" mark
  # (read-only, shown for reference). The builder matches each binding on the
  # (group_name, group_role) pair and silently skips any that resolve to no
  # visible MP — so prog0_loaded is harmless if the FATEK has no program-0
  # mark, and prog1..3 only surface once their seed visibility is 'visible'.
  #
  # @param program_index [Integer] 0-based program index
  # @return [Array<Hash>] { group_name:, group_role: } bindings
  def program_meta_bindings(program_index)
    [
      { group_name: 'system_status', group_role: "humidity_mode_#{program_index}" },
      { group_name: 'system_status', group_role: "prog#{program_index}_loaded" }
    ]
  end

  # Ask the host to re-poll the given (0-based) programs from the FATEK into
  # its mirror. Sets one bit per program in the host's per-slot bitmask
  # register; the host firmware clears each bit once that program's refresh
  # completes (that bit-clear is the completion signal the refresh job waits
  # on before reading the mirror back).
  #
  # @param program_indices [Array<Integer>] 0-based program indices
  def refresh_programs!(program_indices)
    register = host_refresh_register
    if register.nil?
      return
    end

    bitmask = program_indices.inject(0) { |mask, index| mask | (1 << index) }
    if bitmask.zero?
      return
    end

    single_write!(register, bitmask, source: 'program_refresh')
  end

  def refresh_status_register
    host_refresh_register
  end

  def refresh_pending?(program_indices, register_value)
    requested = program_indices.inject(0) { |mask, index| mask | (1 << index) }
    (register_value.to_i & requested) != 0
  end

  private
    # The host's per-slot refresh-trigger register lives on the bridging PLC
    # (group 'ext_device_{slot}', role 'refresh_programs'). Returns nil when
    # this device isn't PLC-relayed.
    def host_refresh_register
      host = host_plc
      if host.nil?
        return nil
      end

      host.measurement_points
        .joins(:register_template)
        .where(register_templates: {
          group_name: "ext_device_#{device.slot_number}",
          group_role: 'refresh_programs'
        })
        .first
    end
end
