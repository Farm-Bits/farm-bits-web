FactoryBot.define do
  factory :modbus_firmware_version do
    model  # default: plc-type model (from the :model factory's default device_type)

    sequence(:name)         { |n| "Firmware #{n}" }
    sequence(:version_code) { |n| "1.0.#{n}" }
    is_latest               { false }
    address_offset          { 0 }

    # Use this trait when the firmware will be attached to a ModbusDevice
    # (peripheral) rather than a PLC. It ensures the underlying Model has
    # device_type='modbus_device' so the ModbusDevice's validation passes.
    trait :for_modbus_device do
      model { association(:model, :modbus_device_type) }
    end

    # Use this trait when you need a host PLC firmware that exposes a
    # relay region for hosting peripherals (Eliwell V2 style).
    trait :host_capable do
      relay_slot_base     { 8968 }
      relay_slot_size     { 1200 }
      relay_max_slots     { 4 }
      relay_register_type { 'holding' }
      relay_read_strategy { RelayReadStrategyRegistry::STRATEGIES.first }
    end

    trait :standard_v1 do
      behavior_profile { 'standard_v1' }
    end
  end

  factory :register_template do
    modbus_firmware_version

    sequence(:name)  { |n| "Register #{n}" }
    sequence(:label) { |n| "REG_#{n}" }
    sequence(:address) { |n| 1_000 + (n * 10) }
    address_count   { 1 }
    register_type   { 'holding' }
    data_type       { 'uint16' }
    byte_order      { 'big_endian' }
    value_format    { 'numeric' }
    factor          { 1.0 }
    offset          { 0.0 }
    category        { 'configuration' }
    user_visibility { 'visible' }
    read_only       { false }
  end

  factory :interface do
    modbus_firmware_version

    sequence(:name)      { |n| "INTF#{n}" }
    sequence(:io_number) { |n| ((n - 1) % 8) + 1 }
    communication_type   { 'digital_output' }

    trait :digital_input  do communication_type { 'digital_input' }  end
    trait :digital_output do communication_type { 'digital_output' } end
    trait :analog_input   do communication_type { 'analog_input' }   end
    trait :analog_output  do communication_type { 'analog_output' }  end
  end

  factory :interface_register_mapping do
    interface
    register_template
  end

  factory :measurement_type do
    sequence(:name) { |n| "Measurement Type #{n}" }
  end

  factory :measurement_subtype do
    measurement_type
    sequence(:name)    { |n| "Subtype #{n}" }
    data_category      { 'analog' }
    value_type         { 'instantaneous' }
    default_unit       { 'units' }
    default_chart_type { 'line' }
    default_color      { '#888888' }

    # data_category and value_type must agree (e.g., status<>step), so we
    # provide ready-made traits for each common combination.

    trait :analog do
      data_category      { 'analog' }
      value_type         { 'instantaneous' }
      default_chart_type { 'line' }
    end

    trait :counter do
      data_category      { 'counter' }
      value_type         { 'accumulative' }
      default_chart_type { 'bar' }
    end

    trait :status do
      data_category      { 'status' }
      value_type         { 'status' }
      default_chart_type { 'step' }
    end
  end
end
