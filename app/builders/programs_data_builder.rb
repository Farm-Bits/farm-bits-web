# Builds the data shape consumed by the Programs show page for a single
# source (Plc or ModbusDevice). The output is fully data-driven: the page
# never references role names directly. Frontend reads register_template
# fields (label, value_format, group_role, validation_rules,
# visibility_conditions, position) to render its phase tables.
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
#         meta: {
#           group_name: 'program_0_meta',
#           registers: [ { register_template:, measurement_point:, position: }, ... ]
#         } | nil
#       },
#       ...
#     ],
#     group_labels: { 'program_*_phase_*' => 'Phase', 'program_*_meta' => 'Program' }
#   }
#
class ProgramsDataBuilder
  CATEGORIES = %w[program_status program_configuration].freeze

  def initialize(source)
    @source = source
  end

  def build
    mps = load_mps
    containers = GroupedRegisterOrganizer.call(mps, categories: CATEGORIES)

    {
      source:       source_summary,
      programs:     build_programs(containers),
      group_labels: collect_group_labels(mps)
    }
  end

  private
    def load_mps
      @source.measurement_points
        .joins(:register_template)
        .where(register_templates: {
          category: CATEGORIES,
          user_visibility: 'visible'
        })
        .includes(:register_template, :measurement_subtype)
        .order('register_templates.position')
        .to_a
    end

    def build_programs(containers)
      containers.keys.sort.map do |container_idx|
        container = containers[container_idx]

        {
          index:  container_idx,
          phases: build_items(container[:items]),
          meta:   build_meta(container[:meta])
        }
      end
    end

    def build_items(items_hash)
      items_hash.keys.sort.map do |item_idx|
        mps = items_hash[item_idx].sort_by { |mp| mp.register_template.position }

        {
          index:      item_idx,
          group_name: mps.first.register_template.group_name,
          registers:  serialize_registers(mps)
        }
      end
    end

    def build_meta(mps)
      if mps.empty?
        return nil
      end

      sorted = mps.sort_by { |mp| mp.register_template.position }
      {
        group_name: sorted.first.register_template.group_name,
        registers:  serialize_registers(sorted)
      }
    end

    def serialize_registers(mps)
      mps.map do |mp|
        {
          register_template: RegisterTemplateSerializer.render_as_json(mp.register_template),
          measurement_point: MeasurementPointSerializer.render_as_json(mp),
          position:          mp.register_template.position
        }
      end
    end

    def collect_group_labels(mps)
      group_names = mps.map { |mp| mp.register_template.group_name }.compact.uniq
      group_names.each_with_object({}) do |name, hash|
        label = PlcBehaviors::GroupSchemas.label_for(name)
        if label.present?
          hash[name] = label
        end
      end
    end

    def source_summary
      { kind: source_kind, id: @source.id, name: @source.name, firmware: @source.modbus_firmware_version&.name }
    end

    def source_kind
      case @source
      when Plc          then 'plc'
      when ModbusDevice then 'modbus_device'
      else                   @source.class.name.underscore
      end
    end
end
