# Behavior: Sync IO active state using individual boolean registers.
#
# Register group:
#   io_active - One boolean per interface. Role pattern: active_{type_prefix}_{io_number}
#               e.g., active_ai_1, active_di_3, active_do_7
#
module PlcBehaviors::Concerns::IoActive
  extend ActiveSupport::Concern

  included do
    register_mp_trigger(
      fields: %w[active],
      method: :sync_io_active!
    )
  end

  ROLE_PREFIX_COMM_TYPES = {
    'active_ai' => 'analog_input',
    'active_di' => 'digital_input',
    'active_do' => 'digital_output',
    'active_ao' => 'analog_output'
  }.freeze

  def sync_io_active!
    io_active_points = find_group('io_active')
    if io_active_points.empty?
      return
    end

    active_io_numbers = compute_active_io_numbers

    writes = []

    io_active_points.each do |mp|
      role = mp.register_template.group_role
      parsed = parse_io_active_role(role)
      if !parsed
        next
      end

      comm_type, io_number = parsed
      is_active = active_io_numbers[comm_type]&.include?(io_number) ? 1 : 0
      writes << { measurement_point: mp, value: is_active }
    end

    bulk_write!(writes, source: 'io_active_sync')
  end

  private
    # Parses "active_ai_3" → ['analog_input', 3]
    # Returns nil if the role doesn't match the expected pattern.
    def parse_io_active_role(role)
      ROLE_PREFIX_COMM_TYPES.each do |prefix, comm_type|
        if role.start_with?("#{prefix}_")
          suffix = role.delete_prefix("#{prefix}_")
          io_number = suffix.to_i
          if io_number > 0
            return [comm_type, io_number]
          end
        end
      end

      nil
    end

    # Returns a hash: { 'analog_input' => Set[1, 3, 5], 'digital_output' => Set[1, 2] }
    def compute_active_io_numbers
      io_numbers = Hash.new { |h, k| h[k] = Set.new }

      plc.measurement_points
        .joins(register_template: { interface_register_mappings: :interface })
        .where(active: true)
        .pluck('interfaces.communication_type', 'interfaces.io_number')
        .each { |ct, io_number| io_numbers[ct].add(io_number) }

      io_numbers
    end
end
