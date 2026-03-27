class PlcVersionSerializer < Blueprinter::Base
  identifier :id

  fields :name, :description, :is_latest, :is_supported

  field :group_labels do |plc_version|
    group_names = plc_version.register_templates
      .where.not(group_name: [nil, ''])
      .distinct
      .pluck(:group_name)

    group_names.each_with_object({}) do |name, hash|
      label = PlcBehaviors::GroupSchemas.label_for(name)
      if label.present?
        hash[name] = label
      end
    end
  end
end
