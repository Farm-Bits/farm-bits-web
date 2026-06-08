# Abstract base class for Modbus device behaviors.
#
# Defines every hook the system can call. All are no-ops by default.
# Behavior classes include concerns to override the hooks they support.
#
# HOOKS:
#   sync_clock!                                      - Daily clock sync
#   sync_utc_offset!                                 - Write UTC offset
#   sync_io_active!                                  - Sync IO active state
#   sync_sun_data!(sunrise_minutes, sunset_minutes)  - Write sunrise/sunset
#   cascade_sensor_deactivation!(communication_type, io_number) - Clear sensor refs
#   cleanup_onetime_schedules!                       - Clear expired one-time slots
#
class ModbusBehaviors::Base
  SYSTEM_GROUPS = {}.freeze

  attr_reader :device

  class_attribute :mp_triggers, default: []

  # @param device [Plc, ModbusDevice] the entity this behavior governs.
  def initialize(device)
    @device = device
  end

  # The host PLC for this behavior, if any.
  #
  # - For a Plc: returns itself (it IS the host).
  # - For a PLC-relayed ModbusDevice: returns the host Plc.
  # - For a gateway-direct ModbusDevice: returns nil (no PLC orchestration).
  #
  # Concerns that need to write to host-only registers (e.g., a peripheral's
  # refresh trigger that lives on the host) reach through here.
  def host_plc
    case device
    when Plc
      device
    when ModbusDevice
      device.plc
    end
  end

  def self.register_mp_trigger(fields:, method:)
    self.mp_triggers = mp_triggers + [{ fields: fields.to_set, method: method }]
  end

  def trigger_from_mp_update(changed_fields)
    changed_set = changed_fields.to_set
    mp_triggers.each do |trigger|
      if trigger[:fields].intersect?(changed_set)
        send(trigger[:method])
      end
    end
  end

  # ── Hooks (all no-ops) ──────────────────────────────

  def sync_clock!
  end

  def sync_utc_offset!
  end

  def sync_io_active!
  end

  def sync_sun_data!(sunrise_minutes, sunset_minutes)
  end

  def cascade_sensor_deactivation!(communication_type, io_number)
  end

  def cleanup_onetime_schedules!
  end

  # ── Programs (firmware-specific; default: no programs) ──────────────
  #
  # A "programs" firmware exposes editable program/phase register groups
  # (e.g. FATEK's program_{n}_phase_{m}). Behaviors that support programs
  # override program_group_pattern with a Regexp capturing the 0-based
  # program index and the phase number. The generic builder/controller/UI
  # key off these declarations, never role names.

  def programs?
    program_group_pattern.present?
  end

  def program_group_pattern
    nil
  end

  # The register that reports/sets which program the device currently runs,
  # as { group_name:, group_role: }. nil when the firmware has no active-program
  # concept.
  def active_program_binding
    nil
  end

  # Registers belonging to a program but living outside its phase groups.
  # Array of { group_name:, group_role: } for the given 0-based program index.
  def program_meta_bindings(program_index)
    []
  end

  # Trigger a host-side refresh of the given 0-based programs from the
  # peripheral. No-op unless the firmware supports it.
  def refresh_programs!(program_indices)
  end

  # MP the refresh job re-reads to detect completion (host clears the bit on
  # success). nil when the firmware exposes no such signal.
  def refresh_status_register
    nil
  end

  # Given that register's current value, are any of the requested (0-based)
  # programs still pending refresh?
  def refresh_pending?(program_indices, register_value)
    false
  end

  # Pre-write transform: called by ModbusWriteService before reverse_scaled encoding.
  # Receives the array of { measurement_point:, value: } hashes.
  # Returns the (possibly mutated) array.
  # Override in concerns to adjust MPs or values before reverse_scaled runs.
  def pre_write_transforms(entries)
    entries
  end

  # ── Source-type encoding (firmware-specific; default no-op) ─────────
  #
  # Some host firmwares encode interface communication_type as a small
  # integer (e.g., Eliwell uses 1=AI, 2=DI, 3=DO, 4=AO in om_sensor_cond_*
  # groups). Behaviors that use such an encoding override these two
  # methods; Base returns nil to make callers safe regardless of profile.

  def source_type_for(communication_type)
    nil
  end

  def communication_type_for(source_type)
    nil
  end

  # ── Introspection ───────────────────────────────────

  def supports?(hook_name)
    method(hook_name).owner != ModbusBehaviors::Base
  rescue NameError
    false
  end

  def supported_hooks
    %i[
      sync_clock! sync_utc_offset! sync_io_active! sync_sun_data!
      cascade_sensor_deactivation! cleanup_onetime_schedules!
    ].select { |hook| supports?(hook) }
  end

  def system_groups
    self.class::SYSTEM_GROUPS
  end

  protected
    def find_group(group_name)
      device.measurement_points
        .joins(:register_template)
        .where(register_templates: { group_name: group_name })
        .includes(:register_template)
    end

    def find_group_by_role(group_name)
      find_group(group_name).index_by { |mp| mp.register_template.group_role }
    end

    def find_group_pattern(pattern)
      sql_pattern = pattern.gsub('*', '%')
      device.measurement_points
        .joins(:register_template)
        .where('register_templates.group_name LIKE ?', sql_pattern)
        .includes(:register_template)
    end

    def bulk_write!(writes, source:)
      if writes.empty?
        return
      end

      context = ModbusWriteContext.system_action(source)
      ModbusWriteService.new.bulk_write!(writes, context: context)
    end

    def single_write!(measurement_point, value, source:)
      context = ModbusWriteContext.system_action(source)
      ModbusWriteService.write!(measurement_point, value, context: context)
    end
end
