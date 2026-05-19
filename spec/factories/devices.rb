FactoryBot.define do
  factory :plc do
    transient do
      # When true, skip the after_commit ingestion-service sync so tests
      # don't depend on it being mocked.
      skip_ingestion_sync { true }
    end

    # IMPORTANT: declare firmware FIRST, then derive the model from it.
    # The Plc has a validation that its model must equal its firmware's
    # model, so they MUST come from the same source. By making the
    # firmware the source of truth, every override scenario works:
    #
    #   create(:plc)                              -> firmware uses default plc-type model, plc derives
    #   create(:plc, modbus_firmware_version: f)  -> plc.model = f.model (match)
    #   create(:plc, model: m)                    -> firmware still uses its own default, MISMATCH
    #                                                (don't override model alone; override firmware)

    modbus_firmware_version
    model { modbus_firmware_version.model }

    sequence(:name)          { |n| "PLC #{n}" }
    sequence(:label)         { |n| "PLC-#{n}" }
    sequence(:serial_number) { |n| "PLC-SN-#{n}" }
    sequence(:private_ip)    { |n| "192.168.1.#{(n % 253) + 1}" }
    slave_id                 { 1 }
    sequence(:username)      { |n| "plc_user_#{n}" }
    password                 { 'plc_pass' }
    sequence(:web_username)  { |n| "plc_web_#{n}" }
    web_password             { 'plc_web_pass' }
    active                   { true }
    disable_initial_read     { true }

    gateway

    after(:build) do |plc, evaluator|
      plc.disable_sync_plc_ingestion_service = evaluator.skip_ingestion_sync
    end
  end

  factory :modbus_device do
    # Same firmware-first pattern as :plc. The firmware uses a
    # modbus_device-type Model via the :for_modbus_device trait, so the
    # ModbusDevice's validation passes.
    modbus_firmware_version { association(:modbus_firmware_version, :for_modbus_device) }
    model                   { modbus_firmware_version.model }

    sequence(:name)  { |n| "Device #{n}" }
    sequence(:label) { |n| "DEV-#{n}" }
    slave_id { 1 }

    active                { true }
    disable_initial_read  { true }

    # Default: peripheral wired to a host PLC (relay topology).
    plc

    # Trait for gateway-direct peripherals (no host PLC).
    trait :gateway_direct do
      plc { nil }
      gateway
      sequence(:private_ip) { |n| "192.168.2.#{(n % 253) + 1}" }
    end
  end

  factory :modbus_firmware_compatibility do
    association :host_version, factory: :modbus_firmware_version
    association :peripheral_version, factory: :modbus_firmware_version
    firmware_code { 1 }
  end

  factory :modbus_firmware_relay_mapping do
    modbus_firmware_version
    register_template

    relay_offset { 0 }
    direction    { 'read' }
  end

  factory :measurement_point do
    register_template
    plc

    sequence(:name) { |n| "MP #{n}" }
    position        { 1 }
    active          { true }
    data_collection_enabled  { false }

    after(:build) do |mp, _evaluator|
      mp.register_template ||= build(:register_template,
        modbus_firmware_version: mp.plc&.modbus_firmware_version ||
                                  mp.modbus_device&.modbus_firmware_version)
    end
  end
end
