class RegisterTemplate < ApplicationRecord
  audited

  belongs_to :plc_version

  has_many :interface_register_mappings, dependent: :destroy
  accepts_nested_attributes_for :interface_register_mappings, allow_destroy: true

  has_many :measurement_points, dependent: :destroy

  CATEGORIES = (Interface::CATEGORIES + %w[configuration diagnostic]).freeze
  REGISTER_TYPES = %w[holding input coil discrete].freeze
  DATA_TYPES = %w[
    int8 uint8 int16 uint16 int32 uint32 int64 uint64
    float32 float64
    boolean
    string utf16_string
    date_seconds date_nanoseconds
    time_milliseconds time_nanoseconds
    datetime_seconds datetime_nanoseconds
    timeofday_milliseconds timeofday_nanoseconds
  ].freeze
  BYTE_ORDERS = %w[big_endian little_endian big_endian_swap little_endian_swap].freeze
  VALUE_FORMATS = %w[
    numeric          # Raw numeric value (default)
    boolean          # 0/1 as false/true
    enum             # Numeric value mapped to enum_values
    ascii_string     # Character codes forming ASCII text
    time_of_day      # Time of day in minutes (0-1439)
    duration_seconds # Duration in seconds
    bitmask          # Bitmask value where each bit represents a boolean flag
  ].freeze
  USER_VISIBILITIES = %w[visible hidden].freeze

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
  validate :address_count_matches_data_type
  validate :valid_value_bounds
  validate :enum_values_format, if: :enum_values?
  validate :address_range_does_not_overlap
  validate :group_role_requires_group_name
  validate :validation_rules_format
  validate :visibility_conditions_format
  validate :bulk_read_offset_requires_bulk_read_address
  validates :user_visibility, presence: true, inclusion: { in: USER_VISIBILITIES }

  def full_address
    "#{address}#{address_count > 1 ? "-#{address + address_count - 1}" : ''}"
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

  def numeric_register?
    value_format == 'numeric'
  end

  def normalize_string_value(value_str)
    case value_format
    when 'boolean'
      ActiveModel::Type::Boolean.new.cast(value_str)
    when 'numeric'
      begin
        Float(value_str)
      rescue ArgumentError, TypeError
        nil
      end
    else
      value_str
    end
  end

  def decode_data(data)
    case value_format
    when 'numeric'
      decode_numeric(data)
    when 'boolean'
      data.first != 0
    when 'enum'
      data.first
    when 'ascii_string'
      decode_ascii_string(data)
    when 'time_of_day'
      decode_time_of_day(data)
    when 'duration_seconds'
      decode_duration_seconds(data)
    when 'bitmask'
      decode_numeric(data)
    else
      data.first
    end
  end

  def encode_value(value)
    case value_format
    when 'numeric'
      encode_numeric(value)
    when 'boolean'
      [value ? 1 : 0]
    when 'enum'
      [value.to_i]
    when 'ascii_string'
      encode_ascii_string(value)
    when 'time_of_day'
      encode_time_of_day(value)
    when 'duration_seconds'
      encode_duration_seconds(value)
    when 'bitmask'
      encode_numeric(value)
    else
      [value.to_i]
    end
  end

  def decode_bitmask_labels(raw_value)
    if !enum_values.present?
      return []
    end

    value = raw_value.to_i
    enum_values.filter_map do |bit_str, label|
      bit = bit_str.to_i
      if (value & (1 << bit)) != 0
        label
      end
    end
  end

  def encode_bitmask_from_bits(bit_positions)
    bit_positions.map(&:to_i).reduce(0) { |mask, bit| mask | (1 << bit) }
  end

  private
    def minimum_address_count
      case data_type
      when 'int8', 'uint8', 'boolean', 'int16', 'uint16' then 1
      when 'int32', 'uint32', 'float32',
          'date_seconds', 'time_milliseconds',
          'datetime_seconds', 'timeofday_milliseconds' then 2
      when 'int64', 'uint64', 'float64',
          'date_nanoseconds', 'time_nanoseconds',
          'datetime_nanoseconds', 'timeofday_nanoseconds' then 4
      when 'string', 'utf16_string' then 1
      else 1
      end
    end

    def address_count_matches_data_type
      if !data_type.present? || !address_count.present?
        return
      end

      min = minimum_address_count
      if address_count < min
        errors.add(:address_count, "must be at least #{min} for data type '#{data_type}' (#{name})")
      end
    end

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

    def validate_required_when_format(rule_config)
      if !rule_config.is_a?(Hash)
        errors.add(:validation_rules, "required_when must be an object")
        return
      end

      if !rule_config['group_role'].present?
        errors.add(:validation_rules, "required_when must have 'group_role'")
      end

      if !rule_config.key?('equals') && !rule_config.key?('not_equals')
        errors.add(:validation_rules, "required_when must have 'equals' or 'not_equals'")
      end
    end

    def validate_required_when_any_format(rule_config)
      if !rule_config.is_a?(Array)
        errors.add(:validation_rules, "required_when_any must be an array")
        return
      end

      rule_config.each do |condition|
        validate_required_when_format(condition)
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
        when 'required_when_any'
          validate_required_when_any_format(rule_config)
        when 'one_of_required'
          validate_one_of_required_format(rule_config)
        when 'less_than', 'greater_than'
          validate_comparison_format(rule_type, rule_config)
        end
      end
    end

    def visibility_conditions_format
      if visibility_conditions.blank?
        return
      end

      if !visibility_conditions.is_a?(Hash)
        errors.add(:visibility_conditions, 'must be a JSON object')
        return
      end

      visibility_conditions.each do |controller_role, expected_values|
        if !controller_role.is_a?(String) || controller_role.blank?
          errors.add(:visibility_conditions, 'keys must be non-empty strings (group_role references)')
          next
        end

        normalized = Array.wrap(expected_values)
        if !normalized.all? { |v| v.is_a?(String) || v.is_a?(Numeric) }
          errors.add(:visibility_conditions, "values for '#{controller_role}' must be strings or numbers")
        end
      end
    end

    def bulk_read_offset_requires_bulk_read_address
      if bulk_read_offset.present? && bulk_read_address.blank?
        errors.add(:bulk_read_offset, 'cannot be set without bulk_read_address')
      end
    end

    def decode_numeric(data)
      case data_type
      when 'uint8'
        data.first & 0xFF
      when 'int8'
        val = data.first & 0xFF
        val > 127 ? val - 256 : val
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
      when 'uint64'
        (data[0] << 48) | (data[1] << 32) | (data[2] << 16) | data[3]
      when 'int64'
        val = (data[0] << 48) | (data[1] << 32) | (data[2] << 16) | data[3]
        val > 9223372036854775807 ? val - 18446744073709551616 : val
      when 'float32'
        data.pack('S>*').unpack1('g')
      when 'float64'
        data.pack('S>*').unpack1('G')
      when 'date_seconds', 'datetime_seconds', 'time_milliseconds', 'timeofday_milliseconds'
        (data[0] << 16) | data[1]  # 32-bit timestamp/duration
      when 'date_nanoseconds', 'datetime_nanoseconds', 'time_nanoseconds', 'timeofday_nanoseconds'
        (data[0] << 48) | (data[1] << 32) | (data[2] << 16) | data[3]  # 64-bit timestamp/duration
      else
        data.first
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

    def decode_time_of_day(data)
      total_minutes = decode_numeric(data).to_i
      total_minutes = total_minutes.clamp(0, 1439)

      hours = total_minutes / 60
      minutes = total_minutes % 60

      format('%02d:%02d', hours, minutes)
    end

    def decode_duration_seconds(data)
      total_seconds = decode_numeric(data).to_i

      hours = total_seconds / 3600
      minutes = (total_seconds % 3600) / 60
      seconds = total_seconds % 60

      if hours > 0
        format('%02d:%02d:%02d', hours, minutes, seconds)
      else
        format('%02d:%02d', minutes, seconds)
      end
    end

    def encode_numeric(value)
      case data_type
      when 'uint8', 'int8'
        [value.to_i & 0xFF]
      when 'uint16', 'int16'
        [value.to_i & 0xFFFF]
      when 'uint32', 'int32', 'date_seconds', 'datetime_seconds', 'time_milliseconds', 'timeofday_milliseconds'
        val = value.to_i
        [(val >> 16) & 0xFFFF, val & 0xFFFF]
      when 'uint64', 'int64', 'date_nanoseconds', 'datetime_nanoseconds', 'time_nanoseconds', 'timeofday_nanoseconds'
        val = value.to_i
        [(val >> 48) & 0xFFFF, (val >> 32) & 0xFFFF, (val >> 16) & 0xFFFF, val & 0xFFFF]
      when 'float32'
        [value.to_f].pack('g').unpack('S>*')
      when 'float64'
        [value.to_f].pack('G').unpack('S>*')
      else
        [value.to_i]
      end
    end

    def encode_ascii_string(value)
      padded = value.to_s.ljust(address_count * 2, "\x00")

      padded.bytes.each_slice(2).map do |high, low|
        (high << 8) | (low || 0)
      end
    end

    def encode_time_of_day(value)
      minutes = if value.is_a?(String) && value.include?(':')
        parts = value.split(':')
        (parts[0].to_i * 60) + parts[1].to_i
      else
        value.to_i
      end

      minutes = minutes.clamp(0, 1439)
      encode_numeric(minutes)
    end

    def encode_duration_seconds(value)
      seconds = if value.is_a?(String) && value.include?(':')
        parts = value.split(':').map(&:to_i)
        case parts.length
        when 3
          (parts[0] * 3600) + (parts[1] * 60) + parts[2]
        when 2
          (parts[0] * 60) + parts[1]
        else
          value.to_i
        end
      else
        value.to_i
      end

      encode_numeric(seconds)
    end
end
