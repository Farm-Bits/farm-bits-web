# Refreshes one or more programs from a PLC-relayed peripheral into the host
# mirror, then reads the fresh values back into our DB.
#
# Per-program by default (the host pulls each program over RS-485 separately),
# but accepts an array so a future "refresh all" is just [0, 1, 2, 3].
#
# Flow (self-rescheduling, never sleeps a worker):
#   attempt 0 : write the refresh bitmask (behavior.refresh_programs!),
#               enqueue a read of the status register, reschedule
#   attempt k : re-read the status register; if the requested bits have
#               cleared (host finished), read the program registers back and
#               stop. Otherwise re-read the status register and reschedule,
#               up to MAX_ATTEMPTS (then read back best-effort and warn).
#
class ProgramRefreshJob
  include Sidekiq::Job
  sidekiq_options queue: 'default', retry: false

  POLL_INTERVAL = 3.seconds
  MAX_ATTEMPTS  = 10

  def perform(source_type, source_id, program_indices, attempt = 0)
    source = resolve_source(source_type, source_id)
    if source.nil?
      return
    end

    behavior = ModbusBehaviors.for(source)
    indices  = Array(program_indices).map(&:to_i)
    if indices.empty?
      return
    end

    if attempt.zero?
      start_refresh(source_type, source_id, behavior, indices)
      return
    end

    register = behavior.refresh_status_register

    # No completion signal, or the host has cleared the bits: read back and stop.
    if register.nil? || !behavior.refresh_pending?(indices, register.last_decoded_value)
      read_back_programs(source, behavior, indices)
      return
    end

    if attempt >= MAX_ATTEMPTS
      Rails.logger.warn(
        "[ProgramRefreshJob] #{source_type} #{source_id} refresh of programs " \
        "#{indices.inspect} timed out after #{attempt} attempts; reading back best-effort"
      )
      read_back_programs(source, behavior, indices)
      return
    end

    enqueue_status_read(behavior)
    reschedule(source_type, source_id, indices, attempt + 1)
  end

  private
    def resolve_source(source_type, source_id)
      case source_type
      when 'modbus_device' then ModbusDevice.find_by(id: source_id)
      when 'plc'           then Plc.find_by(id: source_id)
      end
    end

    def start_refresh(source_type, source_id, behavior, indices)
      behavior.refresh_programs!(indices)
      enqueue_status_read(behavior)
      reschedule(source_type, source_id, indices, 1)
    rescue => e
      Rails.logger.warn("[ProgramRefreshJob] failed to start refresh: #{e.class} - #{e.message}")
    end

    def reschedule(source_type, source_id, indices, attempt)
      self.class.perform_in(POLL_INTERVAL, source_type, source_id, indices, attempt)
    end

    def enqueue_status_read(behavior)
      register = behavior.refresh_status_register
      if register.nil?
        return
      end

      ModbusReadEnqueuer.enqueue([register])
    end

    # Read back the registers belonging to the refreshed programs: each
    # program's phase groups (matched via the behavior's pattern) plus its
    # per-program meta bindings. Read-back is one batched endpoint call.
    def read_back_programs(source, behavior, indices)
      pattern = behavior.program_group_pattern
      if pattern.nil?
        return
      end

      measurement_points = source.measurement_points
        .joins(:register_template)
        .where(register_templates: { user_visibility: 'visible' })
        .includes(:register_template)
        .to_a

      index_set = indices.to_set

      phase_points = measurement_points.select do |mp|
        match = pattern.match(mp.register_template.group_name.to_s)
        match && index_set.include?(match[1].to_i)
      end

      meta_points = indices.flat_map do |index|
        behavior.program_meta_bindings(index).filter_map do |binding|
          measurement_points.find do |mp|
            template = mp.register_template
            template.group_name == binding[:group_name] && template.group_role == binding[:group_role]
          end
        end
      end

      targets = (phase_points + meta_points).uniq
      if targets.empty?
        return
      end

      ModbusReadEnqueuer.enqueue(targets)
    end
end
