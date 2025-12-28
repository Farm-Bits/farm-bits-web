class RegisterTemplate < ApplicationRecord
  audited

  belongs_to :plc_version
  belongs_to :measurement_subtype, optional: true

  has_one :model, through: :plc_version

  has_one :manufacturer, through: :model

  has_many :measurement_points, dependent: :restrict_with_error

  enum :register_type, {
    holding_register: 0,   # Read/Write (Function codes 3, 6, 16)
    input_register: 1,     # Read-only (Function code 4)
    coil: 2,               # Single bit R/W (Function codes 1, 5, 15)
    discrete_input: 3      # Single bit read-only (Function code 2)
  }

  enum :data_type, {
    int16: 0,
    uint16: 1,
    int32: 2,
    uint32: 3,
    float32: 4,
    float64: 5,
    boolean: 6,
    bcd: 7,                # Binary Coded Decimal
    ascii: 8
  }

  enum :byte_order, {
    big_endian: 0,         # AB CD (most common)
    little_endian: 1,      # CD AB
    big_endian_swap: 2,    # BA DC (mid-big endian)
    little_endian_swap: 3  # DC BA (mid-little endian)
  }

  enum :register_category, {
    measurement: 0,        # Linked to MeasurementSubtype, stored in timeseries
    configuration: 1,      # Device settings, also tracked in timeseries
    control: 2,            # Commands to device (setpoints, triggers)
    status: 3,             # Device status flags, diagnostics
    identification: 4      # Device info (serial, firmware version, etc.)
  }

  # ===========================================
  # Validations
  # ===========================================
  validates :address, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :address, uniqueness: { scope: :firmware_version_id }
  validates :name, presence: true
  validates :name, uniqueness: { scope: :firmware_version_id, case_sensitive: false }
  validates :register_type, presence: true
  validates :data_type, presence: true
  validates :register_category, presence: true
  validates :address_count, numericality: { only_integer: true, greater_than: 0 }
  validates :scale_factor, numericality: true
  validates :offset, numericality: true
  validates :default_polling_interval_seconds, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :measurement_subtype_required_for_measurement_category
  validate :valid_value_bounds

  def full_address
    "#{address}#{address_count > 1 ? "-#{address + address_count - 1}" : ''}"
  end

  def transform_value(raw_value)
    if raw_value.nil?
      return nil
    end

    (raw_value.to_f * scale_factor) + offset
  end

  def effective_unit
    unit.presence || measurement_subtype&.default_unit
  end

  def effective_chart_type
    measurement_subtype&.effective_chart_type || 'line'
  end

  def effective_color
    measurement_subtype&.default_color || '#6B7280'
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

  # Number of bytes for this data type
  def byte_size
    case data_type
    when 'int16', 'uint16' then 2
    when 'int32', 'uint32', 'float32' then 4
    when 'float64' then 8
    when 'boolean' then 1
    else 2
    end
  end

  # Check if value is within bounds
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

  # Get enum label for a given value
  def enum_label(value)
    if enum_values.blank?
      return nil
    end

    enum_values[value.to_s]
  end

  # Value type from measurement_subtype
  delegate :value_type, to: :measurement_subtype, allow_nil: true

  private
    def measurement_subtype_required_for_measurement_category
      if register_category_measurement? && measurement_subtype.nil?
        errors.add(:measurement_subtype, 'is required for measurement registers')
      end
    end

    def valid_value_bounds
      if !min_value.present? || !max_value.present?
        return
      end

      if min_value >= max_value
        errors.add(:min_value, 'must be less than maximum value')
      end
    end
end
