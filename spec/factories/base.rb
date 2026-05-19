FactoryBot.define do
  factory :manufacturer do
    sequence(:name) { |n| "Manufacturer #{n}" }
  end

  factory :model do
    manufacturer
    sequence(:name) { |n| "Model #{n}" }
    device_type { 'plc' }

    trait :gateway_type        do device_type { 'gateway' }        end
    trait :plc_type            do device_type { 'plc' }            end
    trait :modbus_device_type  do device_type { 'modbus_device' }  end
  end

  factory :gateway do
    model { association(:model, :gateway_type) }

    sequence(:name)          { |n| "Gateway #{n}" }
    sequence(:label)         { |n| "GW#{n}" }
    sequence(:imei)          { |n| "%015d" % (100_000_000 + n) }
    sequence(:serial_number) { |n| "GW-SN-#{n}" }
    sequence(:private_ip)    { |n| "10.10.#{(n / 254) % 255}.#{(n % 253) + 1}" }
    username                 { 'gw_user' }
    password                 { 'gw_pass' }
    active                   { true }
  end
end
