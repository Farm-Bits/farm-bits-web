require 'rails_helper'

# sync_io_active! reads the active state of each interface's measurement
# points and writes a 1 or 0 to the matching active_{type}_{io_number} register.

RSpec.describe ModbusBehaviors::StandardV1, '#sync_io_active!' do
  let!(:firmware) { create(:modbus_firmware_version, :standard_v1) }
  let!(:plc)      { create(:plc, modbus_firmware_version: firmware) }
  let(:behavior)  { described_class.new(plc) }

  let!(:ai1) { create(:interface, :analog_input, modbus_firmware_version: firmware, io_number: 1) }
  let!(:ai2) { create(:interface, :analog_input, modbus_firmware_version: firmware, io_number: 2) }
  let!(:do1) { create(:interface, :digital_output, modbus_firmware_version: firmware, io_number: 1) }
  let!(:do2) { create(:interface, :digital_output, modbus_firmware_version: firmware, io_number: 2) }

  let!(:io_active_mps) do
    {
      'active_ai_1' => 6_000,
      'active_ai_2' => 6_001,
      'active_do_1' => 6_010,
      'active_do_2' => 6_011
    }.map do |role, addr|
      template = create(
        :register_template,
        modbus_firmware_version: firmware,
        group_name: 'io_active',
        group_role: role,
        address: addr,
        category: 'configuration'
      )
      [role, create(:measurement_point, plc: plc, register_template: template, name: "IoActive #{role}")]
    end.to_h
  end

  # Data-category MPs: AI1=active, AI2=inactive, DO1=active, DO2=inactive
  let!(:ai1_data) { build_data_mp(ai1, 'analog', active: true) }
  let!(:ai2_data) { build_data_mp(ai2, 'analog', active: false) }
  let!(:do1_data) { build_data_mp(do1, 'status', active: true) }
  let!(:do2_data) { build_data_mp(do2, 'status', active: false) }

  it 'writes 1 for active interfaces and 0 for inactive interfaces' do
    captured = nil
    allow_any_instance_of(ModbusWriteService).to receive(:bulk_write!) do |_svc, entries, **_kwargs|
      captured = entries.to_h do |e|
        [e[:measurement_point].register_template.group_role, e[:value]]
      end
      { success: true, results: {} }
    end

    behavior.sync_io_active!

    expect(captured).to eq(
      'active_ai_1' => 1,
      'active_ai_2' => 0,
      'active_do_1' => 1,
      'active_do_2' => 0
    )
  end

  it 'does nothing when no io_active registers exist on the firmware' do
    io_active_mps.values.each(&:destroy)

    expect_any_instance_of(ModbusWriteService).not_to receive(:bulk_write!)

    behavior.sync_io_active!
  end

  private
    def build_data_mp(interface, data_category, active:)
      template = create(
        :register_template,
        modbus_firmware_version: firmware,
        category: data_category,
        address: 7_000 + interface.id * 10 + (data_category == 'analog' ? 1 : 2)
      )
      create(:interface_register_mapping, interface: interface, register_template: template)

      subtype_trait = data_category == 'status' ? :status : :analog
      subtype       = create(:measurement_subtype, subtype_trait)

      create(
        :measurement_point,
        plc: plc,
        register_template: template,
        measurement_subtype: subtype,
        active: active,
        name: "#{interface.name} data"
      )
    end
end
