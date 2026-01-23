# frozen_string_literal: true

# Service class for validating register groups with cross-field dependencies
#
# This validator handles:
# - Conditional visibility based on controller register values
# - Cross-validation rules (less_than, greater_than, required_when)
# - Group-based organization of related settings
#
# Usage:
#   validator = RegisterGroupValidator.new(measurement_points, pending_values)
#   errors = validator.validate
#
class RegisterGroupValidator
  attr_reader :errors

  # @param measurement_points [Array<MeasurementPoint>] Measurement points to validate
  # @param pending_values [Hash] Optional hash of register_template_id => new_value for pending changes
  def initialize(measurement_points, pending_values = {})
    @measurement_points = measurement_points
    @pending_values = pending_values.transform_keys(&:to_i)
    @errors = []
  end

  # Validate all measurement points and return errors
  # @return [Array<String>] Array of error messages
  def validate
    @errors = []

    groups = group_by_group_name
    groups.each do |group_name, points|
      next if group_name.blank?

      validate_group(group_name, points)
    end

    @errors
  end

  # Check if all validations pass
  # @return [Boolean]
  def valid?
    validate.empty?
  end

  private

  # Group measurement points by their register template's group_name
  def group_by_group_name
    @measurement_points.group_by do |mp|
      mp.register_template.group_name
    end
  end

  # Validate all points within a single group
  def validate_group(group_name, points)
    points_by_role = index_by_role(points)

    points.each do |point|
      next unless visible?(point, points_by_role)

      validate_point_rules(point, points_by_role)
    end
  end

  # Index points by their group_role for quick lookup
  def index_by_role(points)
    points.each_with_object({}) do |point, hash|
      role = point.register_template.group_role
      hash[role] = point if role.present?
    end
  end

  # Check if a point should be visible based on visibility_conditions
  def visible?(point, points_by_role)
    conditions = point.register_template.visibility_conditions
    return true if conditions.blank?

    conditions.all? do |controller_role, expected_values|
      controller = points_by_role[controller_role]
      next true unless controller

      controller_value = get_value(controller)
      expected_array = Array.wrap(expected_values).map(&:to_s)

      expected_array.include?(normalize_value(controller_value))
    end
  end

  # Validate all rules for a single point
  def validate_point_rules(point, points_by_role)
    rules = point.register_template.validation_rules
    return if rules.blank?

    validate_required_when(point, points_by_role, rules["required_when"]) if rules["required_when"]
    validate_one_of_required(point, points_by_role, rules["one_of_required"]) if rules["one_of_required"]
    validate_less_than(point, points_by_role, rules["less_than"]) if rules["less_than"]
    validate_greater_than(point, points_by_role, rules["greater_than"]) if rules["greater_than"]
  end

  # Validate: required_when - field is required when controller has specific value
  def validate_required_when(point, points_by_role, rule)
    controller_role = rule["group_role"]
    expected_value = rule["equals"]
    controller = points_by_role[controller_role]

    return unless controller

    controller_value = normalize_value(get_value(controller))
    return unless controller_value == normalize_value(expected_value)

    point_value = get_value(point)
    return unless point_value.blank?

    message = rule["message"] || "#{point.register_template.label} is required when #{controller.register_template.label} is #{expected_value}"
    @errors << message
  end

  # Validate: one_of_required - at least one of the specified roles must have a value
  def validate_one_of_required(point, points_by_role, required_roles)
    has_any_value = required_roles.any? do |role|
      other_point = points_by_role[role]
      value = get_value(other_point)
      value.present?
    end

    return if has_any_value

    role_labels = required_roles.filter_map { |role| points_by_role[role]&.register_template&.label }
    @errors << "At least one of #{role_labels.join(' or ')} is required"
  end

  # Validate: less_than - this value must be less than another field
  def validate_less_than(point, points_by_role, rule)
    comparison_role = rule["group_role"]
    comparison_point = points_by_role[comparison_role]

    return unless comparison_point

    point_value = parse_numeric(get_value(point))
    comparison_value = parse_numeric(get_value(comparison_point))

    return if point_value.nil? || comparison_value.nil?
    return if point_value < comparison_value

    message = rule["message"] || "#{point.register_template.label} must be less than #{comparison_point.register_template.label}"
    @errors << message
  end

  # Validate: greater_than - this value must be greater than another field
  def validate_greater_than(point, points_by_role, rule)
    comparison_role = rule["group_role"]
    comparison_point = points_by_role[comparison_role]

    return unless comparison_point

    point_value = parse_numeric(get_value(point))
    comparison_value = parse_numeric(get_value(comparison_point))

    return if point_value.nil? || comparison_value.nil?
    return if point_value > comparison_value

    message = rule["message"] || "#{point.register_template.label} must be greater than #{comparison_point.register_template.label}"
    @errors << message
  end

  # Get the effective value for a measurement point
  # Prefers pending value over stored value
  def get_value(point)
    return nil unless point

    template_id = point.register_template_id

    if @pending_values.key?(template_id)
      @pending_values[template_id]
    else
      point.last_decoded_value
    end
  end

  # Normalize a value to string for comparison
  def normalize_value(value)
    return "" if value.nil?

    value.to_s.strip
  end

  # Parse a value as numeric, returning nil if not valid
  def parse_numeric(value)
    return nil if value.nil?

    cleaned = value.to_s.strip
    return nil if cleaned.blank?

    Float(cleaned)
  rescue ArgumentError, TypeError
    nil
  end
end
