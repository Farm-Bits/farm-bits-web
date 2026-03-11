# Creates RegisterTemplates and MeasurementPoints for IO health detection
# on all input interfaces (analog_input).
#
# These registers are mapped to each input interface via
# InterfaceRegisterMapping with category: 'interface_configuration'.
#
# Per input interface:
#   detect_mode    - How to detect errors (enum: disabled, exact_match, below/above threshold, out_of_range)
#   detect_value_1 - Primary detection value (error sentinel, threshold, or low bound)
#   detect_value_2 - Secondary value (high bound for out_of_range mode only)
#   health_status  - Read-only. PLC writes: ok, error, unknown
#
# Default seed values:
#   AI: detect_mode=1 (exact_match), detect_value_1=-32768 (disconnected sentinel)
#
# Usage:
#   rails runner db/seeds/phase3_io_health_registers.rb
#

ActiveRecord::Base.transaction do
  IO_HEALTH_BASE_ADDRESS = 16518
  IO_HEALTH_STATUS_BASE_ADDRESS = 9006

  IO_HEALTH_REGISTERS = [
    {
      name_suffix: 'Error Detect Mode',
      label_suffix: 'Error_Detect_Mode',
      description: ->(name) { "#{name} error detection. 0=disabled. 1=exact match. 2=below threshold. 3=above threshold 4=out of range" },
      address_count: 1,
      data_type: 'uint16',
      value_format: 'enum',
      group_role: 'detect_mode',
      read_only: false,
      min_value: 0,
      max_value: 4,
      default_value: 1,
      enum_values: {
        '0' => 'disabled',
        '1' => 'exact_match',
        '2' => 'below_threshold',
        '3' => 'above_threshold',
        '4' => 'out_of_range'
      }
    },
    {
      name_suffix: 'Error Detect Value 1',
      label_suffix: 'Error_Detect_Value_1',
      description: ->(name) { "#{name} error value. exact match: error sentinel. below/above: threshold. out of range: low bound." },
      address_count: 1,
      data_type: 'int16',
      value_format: 'numeric',
      group_role: 'detect_value_1',
      visibility_conditions: { 'detect_mode' => ['1', '2', '3', '4'] },
      read_only: false,
      min_value: -32768,
      max_value: 32767,
      default_value: -32768

    },
    {
      name_suffix: 'Error Detect Value 2',
      label_suffix: 'Error_Detect_Value_2',
      description: ->(name) { "#{name} error value. out_of_range: high bound. Unused in other modes." },
      address_count: 1,
      data_type: 'int16',
      value_format: 'numeric',
      group_role: 'detect_value_2',
      validation_rules: { 'greater_than' => { 'group_role' => 'detect_value_1' }, 'message' => 'high bound must exceed low bound' },
      visibility_conditions: { 'detect_mode' => ['4'] },
      read_only: false,
      min_value: -32768,
      max_value: 32767,
      default_value: 32767
    },
    {
      name_suffix: 'IO Health Status',
      label_suffix: 'IO_Health_Status',
      description: ->(name) { "#{name} health status. 0 = OK. 1 = error. 2 = unknown" },
      address_count: 1,
      data_type: 'uint16',
      value_format: 'enum',
      group_role: 'health_status',
      read_only: true,
      min_value: 0,
      max_value: 2,
      default_value: 0,
      enum_values: {
        '0' => 'ok',
        '1' => 'error',
        '2' => 'unknown'
      }
    }
  ].freeze

  PLC_VERSION_ID = PlcVersion.first.id

  current_position = RegisterTemplate.where(plc_version_id: PLC_VERSION_ID).maximum(:position).to_i + 1
  address_offset = 0
  address_status_offset = 0

  (1..12).each do |n|
    IO_HEALTH_REGISTERS.each do |reg|
      description = reg[:description].call("AI#{n}")

      is_status = reg[:group_role] == 'health_status'

      register_template = RegisterTemplate.create!(
        name: "AI#{n} #{reg[:name_suffix]}",
        label: "AI#{n}_#{reg[:label_suffix]}",
        description: description,
        address: !is_status ? IO_HEALTH_BASE_ADDRESS + address_offset : IO_HEALTH_STATUS_BASE_ADDRESS + address_status_offset,
        address_count: reg[:address_count],
        register_type: 'holding',
        data_type: reg[:data_type],
        byte_order: 'big_endian',
        value_format: reg[:value_format],
        factor: 1.0,
        offset: 0.0,
        category: 'interface_configuration',
        group_name: 'io_health',
        group_role: reg[:group_role],
        validation_rules: reg[:validation_rules],
        visibility_conditions: reg[:visibility_conditions],
        read_only: reg[:read_only],
        min_value: reg[:min_value],
        max_value: reg[:max_value],
        default_value: reg[:default_value],
        enum_values: reg[:enum_values],
        position: current_position,
        plc_version_id: PLC_VERSION_ID
      )

      interface = Interface.find_by(communication_type: 'analog_input', io_number: n, plc_version_id: PLC_VERSION_ID)
      last_position = InterfaceRegisterMapping.where(interface: interface).maximum(:position).to_i + 1
      InterfaceRegisterMapping.create!(
        description: description,
        position: last_position,
        interface: interface,
        register_template: register_template
      )

      if is_status
        address_status_offset += reg[:address_count]
      else
        address_offset += reg[:address_count]
      end
      current_position += 1
    end

  end
end
