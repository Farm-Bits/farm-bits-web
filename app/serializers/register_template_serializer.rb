class RegisterTemplateSerializer < Blueprinter::Base
  identifier :id

  fields :name,
    :label,
    :description,
    :address_count,
    :data_type,
    :value_format,
    :factor,
    :offset,
    :category,
    :group_name,
    :group_role,
    :validation_rules,
    :visibility_conditions,
    :read_only,
    :min_value,
    :max_value,
    :default_value,
    :enum_values,
    :position
end
