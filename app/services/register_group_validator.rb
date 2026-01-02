class RegisterGroupValidator
  def initialize(measurement_points)
    @measurement_points = measurement_points
  end

  def validate
    errors = []

    groups = @measurement_points.group_by do |mp|
      mp.register_template.group_name
    end

    groups.each do |group_name, points|
      if group_name.blank?
        next
      end

      group_errors = validate_group(points)
      errors.concat(group_errors)
    end

    errors
  end

  private
    def validate_group(points)
      errors = []

      points_by_role = points.index_by { |p| p.register_template.group_role }

      points.each do |point|
        rules = point.register_template.validation_rules || {}

        if rules['required_when']
          errors.concat(validate_required_when(point, points_by_role, rules['required_when']))
        end

        if rules['one_of_required']
          errors.concat(validate_one_of_required(point, points_by_role, rules['one_of_required']))
        end

        if rules['less_than']
          errors.concat(validate_less_than(point, points_by_role, rules['less_than']))
        end

        if rules['greater_than']
          errors.concat(validate_greater_than(point, points_by_role, rules['greater_than']))
        end
      end

      errors
    end

    def parse_value(stored_value)
      if stored_value.nil?
        return nil
      end

      stored_value.to_s.strip
    end

    def parse_numeric_value(stored_value)
      if stored_value.nil?
        return nil
      end

      value = stored_value.to_s.strip
      if value.blank?
        return nil
      end

      value.to_f
    end

    def validate_required_when(point, points_by_role, rule)
      errors = []

      controlling_role = rule['group_role']
      expected_value = rule['equals']

      controller = points_by_role[controlling_role]
      if !controller
        return
      end

      actual_value = parse_value(controller.last_decoded_value)
      if actual_value == expected_value
        point_value = parse_value(point.last_decoded_value)

        if point_value.blank?
          errors << "#{point.register_template.label} is required when #{controller.register_template.label} is #{expected_value}"
        end
      end

      errors
    end

    def validate_one_of_required(point, points_by_role, required_roles)
      errors = []

      has_any_value = required_roles.any? do |role|
        other_point = points_by_role[role]
        value = parse_value(other_point&.last_decoded_value)
        value.present?
      end

      if !has_any_value
        role_labels = required_roles.map { |role| points_by_role[role]&.register_template&.label }.compact
        errors << "At least one of #{role_labels.join(' or ')} is required"
      end

      errors
    end

    def validate_less_than(point, points_by_role, rule)
      errors = []

      comparison_role = rule['group_role']
      comparison_point = points_by_role[comparison_role]

      if !comparison_point
        return errors
      end

      point_value = parse_numeric_value(point.last_decoded_value)
      comparison_value = parse_numeric_value(comparison_point.last_decoded_value)

      if point_value.nil? || comparison_value.nil?
        return errors
      end

      if point_value >= comparison_value
        errors << "#{point.register_template.label} must be less than #{comparison_point.register_template.label}"
      end

      errors
    end

    def validate_greater_than(point, points_by_role, rule)
      errors = []

      comparison_role = rule['group_role']
      comparison_point = points_by_role[comparison_role]

      if !comparison_point
        return errors
      end

      point_value = parse_numeric_value(point.last_decoded_value)
      comparison_value = parse_numeric_value(comparison_point.last_decoded_value)

      if point_value.nil? || comparison_value.nil?
        return errors
      end

      if point_value <= comparison_value
        errors << "#{point.register_template.label} must be greater than #{comparison_point.register_template.label}"
      end

      errors
    end
end
