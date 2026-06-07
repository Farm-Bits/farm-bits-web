# Builds the data shape consumed by the Programs show page for a single
# source (Plc or ModbusDevice). Fully data-driven: the page never references
# role names. The only firmware-specific knowledge lives in the source's
# behavior (ModbusBehaviors.for):
#
#   - program_group_pattern   : Regexp matching a phase group_name and
#                               capturing [program_index (0-based), phase_index]
#   - program_meta_bindings(n): per-program registers living outside the phase
#                               groups, as { group_name:, group_role: } entries
#
# Output:
#   {
#     source: { kind:, id:, name:, firmware: },
#     programs: [
#       {
#         index: 0,
#         phases: [
#           {
#             index: 1,
#             group_name: 'program_0_phase_1',
#             registers: [ { register_template:, measurement_point:, position: }, ... ]
#           },
#           ...
#         ],
#         meta: { registers: [ { register_template:, measurement_point:, position: }, ... ] } | nil
#       },
#       ...
#     ]
#   }
#
# Returns nil when the source's firmware has no programs.
#
class ProgramsBuilder
  def initialize(source)
    @source   = source
    @behavior = ModbusBehaviors.for(source)
  end

  def build
    if !@behavior.programs?
      return nil
    end

    measurement_points = load_measurement_points

    {
      source:   source_summary,
      programs: build_programs(index_phases(measurement_points), measurement_points)
    }
  end

  private
    def load_measurement_points
      @source.measurement_points
        .joins(:register_template)
        .where(register_templates: { user_visibility: 'visible' })
        .includes(:register_template, :measurement_subtype)
        .order('register_templates.position')
        .to_a
    end

    # { program_index => { phase_index => [measurement_point, ...] } }
    def index_phases(measurement_points)
      pattern = @behavior.program_group_pattern

      result = Hash.new { |programs, idx| programs[idx] = Hash.new { |phases, p| phases[p] = [] } }

      measurement_points.each do |mp|
        group_name = mp.register_template.group_name
        if group_name.nil?
          next
        end

        match = pattern.match(group_name)
        if match.nil?
          next
        end

        result[match[1].to_i][match[2].to_i] << mp
      end

      result
    end

    def build_programs(phase_index, measurement_points)
      phase_index.keys.sort.map do |program_index|
        {
          index:  program_index,
          phases: build_phases(phase_index[program_index]),
          meta:   build_meta(program_index, measurement_points)
        }
      end
    end

    def build_phases(phases_hash)
      phases_hash.keys.sort.map do |phase_index|
        points = phases_hash[phase_index].sort_by { |mp| mp.register_template.position }

        {
          index:      phase_index,
          group_name: points.first.register_template.group_name,
          registers:  serialize(points)
        }
      end
    end

    def build_meta(program_index, measurement_points)
      bindings = @behavior.program_meta_bindings(program_index)
      if bindings.empty?
        return nil
      end

      matched = bindings.filter_map do |binding|
        measurement_points.find do |mp|
          template = mp.register_template
          template.group_name == binding[:group_name] && template.group_role == binding[:group_role]
        end
      end

      if matched.empty?
        return nil
      end

      { registers: serialize(matched.sort_by { |mp| mp.register_template.position }) }
    end

    def serialize(measurement_points)
      measurement_points.map do |mp|
        {
          register_template: RegisterTemplateSerializer.render_as_json(mp.register_template),
          measurement_point: MeasurementPointSerializer.render_as_json(mp),
          position:          mp.register_template.position
        }
      end
    end

    def source_summary
      {
        kind:     source_kind,
        id:       @source.id,
        name:     @source.name,
        firmware: @source.modbus_firmware_version&.name
      }
    end

    def source_kind
      case @source
      when Plc          then 'plc'
      when ModbusDevice then 'modbus_device'
      else                   @source.class.name.underscore
      end
    end
end
