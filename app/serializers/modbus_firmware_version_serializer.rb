class ModbusFirmwareVersionSerializer < Blueprinter::Base
  identifier :id

  fields :name, :description, :is_latest, :is_supported

  field :group_labels do |modbus_firmware_version|
    group_names =
      if modbus_firmware_version.register_templates.loaded?
        modbus_firmware_version.register_templates.map(&:group_name).compact_blank.uniq
      else
        modbus_firmware_version.register_templates.where.not(group_name: [nil, '']).distinct.pluck(:group_name)
      end

    group_names.each_with_object({}) do |name, hash|
      label = PlcBehaviors::GroupSchemas.label_for(name)
      if label.present?
        hash[name] = label
      end
    end
  end
end
