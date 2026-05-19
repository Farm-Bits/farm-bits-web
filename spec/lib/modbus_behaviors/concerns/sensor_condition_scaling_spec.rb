require 'rails_helper'

# When a sensor condition's source_type or source_io_number is written,
# the threshold and hysteresis MPs in the same group need to use the
# SOURCE interface's scaling (factor/offset) so values reverse-scale
# correctly.

RSpec.describe ModbusBehaviors::Concerns::SensorConditionScaling, '#pre_write_transforms' do
  let!(:firmware) { create(:modbus_firmware_version, :standard_v1) }
  let!(:plc)      { create(:plc, modbus_firmware_version: firmware) }
  let(:behavior)  { ModbusBehaviors::StandardV1.new(plc) }

  let!(:source_mp) do
    template = create(
      :register_template,
      modbus_firmware_version: firmware,
      category: 'analog',
      factor: 0.1,
      offset: -40,
      address: 3_001
    )

    interface = create(
      :interface,
      :analog_input,
      modbus_firmware_version: firmware,
      io_number: 3
    )

    create(
      :interface_register_mapping,
      interface: interface,
      register_template: template
    )

    subtype = create(
      :measurement_subtype,
      :analog,
      name: 'Temperature ambient',
      default_unit: '°C',
      default_color: '#ff0000'
    )

    create(
      :measurement_point,
      plc: plc,
      register_template: template,
      measurement_subtype: subtype,
      active: true,
      name: 'Ambient temp on AI3'
    )
  end

  let!(:cond_mps) do
    %w[source_type source_io_number operator threshold hysteresis].each_with_object({}) do |role, h|
      template = create(
        :register_template,
        modbus_firmware_version: firmware,
        category: 'operation_mode_configuration',
        group_name: 'om_sensor_cond_1',
        group_role: role,
        factor: 1.0,
        offset: 0.0,
        address: 4_001 + h.size
      )
      h[role] = create(
        :measurement_point,
        plc: plc,
        register_template: template,
        name: "Sensor cond 1 #{role}"
      )
    end
  end

  it "propagates the source IO's scaling onto threshold and hysteresis" do
    entries = [
      { measurement_point: cond_mps['source_type'],      value: 1 },  # 1 = analog_input
      { measurement_point: cond_mps['source_io_number'], value: 3 }
    ]

    behavior.pre_write_transforms(entries)

    expect(cond_mps['threshold'].reload.factor_override).to eq(0.1)
    expect(cond_mps['threshold'].reload.offset_override).to eq(-40)
    expect(cond_mps['hysteresis'].reload.factor_override).to eq(0.1)
    expect(cond_mps['hysteresis'].reload.offset_override).to eq(-40)
  end

  it 'clears the overrides when source is set to disabled (type=0)' do
    cond_mps['threshold'].update_columns(factor_override: 0.1, offset_override: -40)
    cond_mps['hysteresis'].update_columns(factor_override: 0.1, offset_override: -40)

    entries = [
      { measurement_point: cond_mps['source_type'],      value: 0 },
      { measurement_point: cond_mps['source_io_number'], value: 0 }
    ]

    behavior.pre_write_transforms(entries)

    expect(cond_mps['threshold'].reload.factor_override).to eq(1.0)
    expect(cond_mps['threshold'].reload.offset_override).to eq(0.0)
  end

  it 'does nothing when the batch contains no source_type / source_io_number changes' do
    entries = [
      { measurement_point: cond_mps['operator'],  value: 1 },
      { measurement_point: cond_mps['threshold'], value: 25 }
    ]

    behavior.pre_write_transforms(entries)

    expect(cond_mps['threshold'].reload.factor_override).to be_nil
    expect(cond_mps['threshold'].reload.offset_override).to be_nil
  end
end
