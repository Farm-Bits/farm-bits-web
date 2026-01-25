class RegisterTemplateSerializer < Blueprinter::Base
  identifier :id

  fields :name,
    :label,
    :description,
    :address_count,
    :data_type,
    :value_format,
    :category,
    :group_name,
    :group_role,
    :validation_rules,
    :visibility_conditions,
    :read_only,
    :default_value,
    :enum_values,
    :position

  field :factor do |rt|
    rt.factor&.to_f
  end

  field :offset do |rt|
    rt.offset&.to_f
  end

  field :min_value do |rt|
    rt.min_value&.to_f
  end

  field :max_value do |rt|
    rt.max_value&.to_f
  end
end
