# Organizes a collection of MeasurementPoints into a container/item tree
# based on group structure declared in PlcBehaviors::GroupSchemas.
#
# Generic: knows nothing about programs, phases, operation modes, or any
# specific feature. Given MPs whose register_templates have group_names
# matching schemas with `structure: { kind:, container_index:, item_index: }`
# declarations, returns a hash keyed by container index.
#
# Output shape:
#   {
#     0 => { items: { 1 => [mp, mp, ...], 2 => [...] }, meta: [mp, mp] },
#     1 => { items: {}, meta: [...] },
#     ...
#   }
#
# MPs whose group_name does not match a schema with structure declarations
# are silently skipped (they don't belong to a container/item layout).
#
class GroupedRegisterOrganizer
  def self.call(measurement_points, categories: nil)
    new(measurement_points, categories: categories).call
  end

  def initialize(measurement_points, categories: nil)
    @measurement_points = measurement_points
    @categories         = categories
  end

  def call
    containers = Hash.new { |h, k| h[k] = { items: Hash.new { |hh, kk| hh[kk] = [] }, meta: [] } }

    filtered.each do |mp|
      parsed = PlcBehaviors::GroupSchemas.parse_indices(mp.register_template.group_name)
      if !parsed
        next
      end

      container_idx = parsed[:container]
      if container_idx.nil?
        next
      end

      case parsed[:kind]
      when :item
        containers[container_idx][:items][parsed[:item]] << mp
      when :container
        containers[container_idx][:meta] << mp
      end
    end

    containers
  end

  private
    def filtered
      if @categories.nil?
        return @measurement_points
      end

      @measurement_points.select do |mp|
        @categories.include?(mp.register_template.category)
      end
    end
end
