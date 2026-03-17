class PlcVersionSerializer < Blueprinter::Base
  identifier :id

  fields :name, :description, :is_latest, :is_supported, :behavior_profile

  field :behavior_ui_hints do |plc_version|
    behavior_class = PlcBehaviors.class_for(plc_version.behavior_profile)
    if !behavior_class
      return {}
    end

    behavior_class.ui_hints_for_groups
  end
end
