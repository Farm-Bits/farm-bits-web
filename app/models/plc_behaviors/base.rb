# Abstract base class for PLC behaviors.
#
# Defines every hook the system can call. All are no-ops by default.
# Behavior classes include concerns to override the hooks they support.
#
# HOOKS:
#   sync_clock!                                     - Daily clock sync
#   sync_utc_offset!                                - Write UTC offset
#   sync_io_active!                                 - Sync IO active state
#   sync_sun_data!(sunrise_minutes, sunset_minutes)  - Write sunrise/sunset
#   cascade_sensor_deactivation!(communication_type, io_number) - Clear sensor refs
#   cleanup_onetime_schedules!                       - Clear expired one-time slots
#
class PlcBehaviors::Base
  SYSTEM_GROUPS = {}.freeze

  SOURCE_TYPE_MAP = {
    'analog_input'   => 1,
    'digital_input'  => 2,
    'digital_output' => 3,
    'analog_output'  => 4
  }.freeze

  attr_reader :plc

  class_attribute :mp_triggers, default: []

  def initialize(plc)
    @plc = plc
  end

  def self.ui_hints_for_groups
    self::SYSTEM_GROUPS
      .select { |_name, config| config[:ui_hints].present? }
      .transform_values { |config| config[:ui_hints] }
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

  # ── Introspection ───────────────────────────────────

  def supports?(hook_name)
    method(hook_name).owner != PlcBehaviors::Base
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
      plc.measurement_points
        .joins(:register_template)
        .where(register_templates: { group_name: group_name })
        .includes(:register_template)
    end

    def find_group_by_role(group_name)
      find_group(group_name).index_by { |mp| mp.register_template.group_role }
    end

    def find_group_pattern(pattern)
      sql_pattern = pattern.gsub('*', '%')
      plc.measurement_points
        .joins(:register_template)
        .where('register_templates.group_name LIKE ?', sql_pattern)
        .includes(:register_template)
    end

    def bulk_write!(writes, source:)
      if writes.empty?
        return
      end

      context = PlcWriteContext.system_action(source)
      service = PlcWriteService.new(writes.first[:measurement_point])
      service.bulk_write!(writes, context: context)
    end

    def single_write!(measurement_point, value, source:)
      context = PlcWriteContext.system_action(source)
      service = PlcWriteService.new(measurement_point)
      service.write!(value, context: context)
    end

    # Resolve communication_type string to source_type integer
    def source_type_for(communication_type)
      SOURCE_TYPE_MAP[communication_type]
    end
end
