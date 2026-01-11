class RegisterTemplateSerializer < Blueprinter::Base
  identifier :id

  fields :name,
    :label,
    :description,
    :factor,
    :offset,
    :category,
    :group_name,
    :read_only,
    :min_value,
    :max_value,
    :default_value,
    :enum_values
end
