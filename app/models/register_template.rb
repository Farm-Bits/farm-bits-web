class RegisterTemplate < ApplicationRecord
  audited

  belongs_to :plc_version
  belongs_to :interface, optional: true

  has_many :measurement_points, dependent: :restrict_with_error

  CATEGORIES = %w[sensor control configuration diagnostic identification].freeze
  REGISTER_TYPES = %w[holding input coil discrete].freeze
  DATA_TYPES = %w[int16 uint16 int32 uint32 float32 boolean].freeze
  BYTE_ORDERS = %w[big_endian little_endian big_endian_swap little_endian_swap].freeze
  VALUE_FORMATS = %w[
    numeric      # Raw numeric value (default)
    boolean      # 0/1 as false/true
    enum         # Numeric value mapped to enum_values
    ascii_string # Character codes forming ASCII text
  ].freeze

  validates :name, presence: true, uniqueness: { scope: :plc_version_id }
  validates :label, presence: true, uniqueness: { scope: :plc_version_id }
  validates :address,
    presence: true,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0,
      message: 'must be greater than or equal to 0 (Modbus specification)'
    },
    uniqueness: { scope: :plc_version_id }
  validates :address_count, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :register_type, presence: true, inclusion: { in: REGISTER_TYPES }
  validates :data_type, presence: true, inclusion: { in: DATA_TYPES }
  validates :byte_order, presence: true, inclusion: { in: BYTE_ORDERS }
  validates :value_format, presence: true, inclusion: { in: VALUE_FORMATS }
  validates :factor, numericality: true
  validates :offset, numericality: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :default_polling_interval_seconds, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :valid_value_bounds
  validate :enum_values_format, if: :enum_values?
  validate :address_range_does_not_overlap
  validate :group_role_requires_group_name
  validate :validation_rules_format

  def full_address
    "#{address}#{address_count > 1 ? "-#{address + address_count - 1}" : ''}"
  end

  def transform_value(raw_value)
    if raw_value.nil?
      return nil
    end

    (raw_value.to_f * factor) + offset
  end

  def read_function_code
    case register_type
    when 'holding_register' then 3
    when 'input_register' then 4
    when 'coil' then 1
    when 'discrete_input' then 2
    end
  end

  def write_function_code
    if read_only?
      return nil
    end

    case register_type
    when 'holding_register' then 6
    when 'coil' then 5
    else nil
    end
  end

  def byte_size
    case data_type
    when 'int16', 'uint16' then 2
    when 'int32', 'uint32', 'float32' then 4
    when 'float64' then 8
    when 'boolean' then 1
    else 2
    end
  end

  def value_in_bounds?(value)
    if min_value.nil? && max_value.nil?
      return true
    end

    if max_value.nil?
      return value >= min_value
    end

    if min_value.nil?
      return value <= max_value
    end

    value >= min_value && value <= max_value
  end

  def string_register?
    value_format == 'ascii_string'
  end

  def enum_register?
    value_format == 'enum' && enum_values.present?
  end

  def numeric_register?
    value_format == 'numeric'
  end

  def decode_data(data)
    case value_format
    when 'ascii_string'
      decode_ascii_string(data)
    when 'enum'
      data.first
    when 'boolean'
      data.first != 0
    when 'numeric'
      decode_numeric(data)
    else
      data.first
    end
  end

  def encode_value(value)
    case value_format
    when 'ascii_string'
      encode_ascii_string(value)
    when 'enum'
      [value.to_i]
    when 'boolean'
      [value ? 1 : 0]
    when 'numeric'
      encode_numeric(value)
    else
      [value.to_i]
    end
  end

  def enum_options
    if !enum_values.present?
      return []
    end

    enum_values.map { |k, v| { value: k.to_i, label: v } }
  end

  private
    def valid_value_bounds
      if !min_value.present? || !max_value.present?
        return
      end

      if min_value > max_value
        errors.add(:min_value, 'must be less than maximum value')
      end
    end

    def enum_values_format
      if !enum_values.is_a?(Hash)
        return
      end

      if !enum_values.keys.all? { |k| k.to_s.match?(/^\d+$/) }
        errors.add(:enum_values, "keys must be numeric")
      end

      if !enum_values.values.all? { |v| v.is_a?(String) }
        errors.add(:enum_values, "values must be strings")
      end
    end

    def address_range_does_not_overlap
      if !plc_version_id.present? || !address.present? || !address_count.present?
        return
      end

      start_addr = address
      end_addr = address + address_count - 1

      overlapping = RegisterTemplate
        .where(plc_version_id: plc_version_id, register_type: register_type)
        .where.not(id: id)
        .where('address <= ? AND (address + address_count - 1) >= ?', end_addr, start_addr)

      if overlapping.exists?
        overlapping_register = overlapping.first
        errors.add(
          :address,
          "range #{start_addr}-#{end_addr} overlaps with '#{overlapping_register.name}' " \
          "(#{overlapping_register.address}-#{overlapping_register.address + overlapping_register.address_count - 1})"
        )
      end
    end

    def group_role_requires_group_name
      if group_role.present? && group_name.blank?
        errors.add(:group_role, 'cannot be set without a group_name')
      end
    end

    def validation_rules_format
      if validation_rules.blank?
        return
      end

      if !validation_rules.is_a?(Hash)
        errors.add(:validation_rules, 'must be a JSON object')
        return
      end

      validation_rules.each do |rule_type, rule_config|
        case rule_type
        when 'required_when'
          validate_required_when_format(rule_config)
        when 'one_of_required'
          validate_one_of_required_format(rule_config)
        when 'less_than', 'greater_than'
          validate_comparison_format(rule_type, rule_config)
        end
      end
    end

    def validate_required_when_format(rule_config)
      if !rule_config.is_a?(Hash)
        errors.add(:validation_rules, "required_when must be an object")
        return
      end

      if !rule_config['group_role'].present?
        errors.add(:validation_rules, "required_when must have 'group_role'")
      end

      if !rule_config.key?('equals')
        errors.add(:validation_rules, "required_when must have 'equals'")
      end
    end

    def validate_one_of_required_format(rule_config)
      if !rule_config.is_a?(Array)
        errors.add(:validation_rules, "one_of_required must be an array")
        return
      end

      if rule_config.empty?
        errors.add(:validation_rules, "one_of_required cannot be empty")
      end

      if !rule_config.all? { |role| role.is_a?(String) }
        errors.add(:validation_rules, "one_of_required must contain only strings")
      end
    end

    def validate_comparison_format(rule_type, rule_config)
      if !rule_config.is_a?(Hash)
        errors.add(:validation_rules, "#{rule_type} must be an object")
        return
      end

      if !rule_config['group_role'].present?
        errors.add(:validation_rules, "#{rule_type} must have 'group_role'")
      end
    end

    def decode_ascii_string(data)
      data.flat_map do |value|
        high_byte = (value >> 8) & 0xFF
        low_byte = value & 0xFF
        [high_byte, low_byte]
      end
      .take_while { |byte| byte != 0 }
      .pack('C*')
      .force_encoding('ASCII')
    end

    def decode_numeric(data)
      case data_type
      when 'uint16'
        data.first
      when 'int16'
        val = data.first
        val > 32767 ? val - 65536 : val
      when 'uint32'
        (data[0] << 16) | data[1]
      when 'int32'
        val = (data[0] << 16) | data[1]
        val > 2147483647 ? val - 4294967296 : val
      when 'float32'
        data.pack('S>*').unpack1('g')
      else
        data.first
      end
    end

    def encode_ascii_string(value)
      padded = value.to_s.ljust(address_count * 2, "\x00")

      padded.bytes.each_slice(2).map do |high, low|
        (high << 8) | (low || 0)
      end
    end

    def encode_numeric(value)
      case data_type
      when 'uint16', 'int16'
        [value.to_i & 0xFFFF]
      when 'uint32', 'int32'
        val = value.to_i
        [(val >> 16) & 0xFFFF, val & 0xFFFF]
      when 'float32'
        [value.to_f].pack('g').unpack('S>*')
      else
        [value.to_i]
      end
    end
end
