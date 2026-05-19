require 'rails_helper'

# Tests the sync_clock! behavior method directly answering:
# "how do I verify it writes the proper value at the proper register?"

RSpec.describe ModbusBehaviors::StandardV1, '#sync_clock!' do
  # let! for firmware and plc so the Plc's after_create callback doesn't
  # auto-create MPs that collide with the ones we make explicitly below.
  let!(:firmware) { create(:modbus_firmware_version, :standard_v1) }
  let!(:plc)      { create(:plc, modbus_firmware_version: firmware) }
  let(:behavior)  { described_class.new(plc) }

  let!(:clock_mps) do
    roles = %w[seconds minutes hours day_of_week day_of_month month year upload_trigger]
    roles.each_with_index.map do |role, i|
      template = create(
        :register_template,
        modbus_firmware_version: firmware,
        group_name: 'set_system_clock',
        group_role: role,
        address: 5_000 + i,
        category: 'configuration'
      )
      create(
        :measurement_point,
        plc: plc,
        register_template: template,
        name: "Clock #{role}"
      )
    end
  end

  it 'writes the current UTC time components to the right registers' do
    captured_bulk = nil
    allow_any_instance_of(ModbusWriteService).to receive(:bulk_write!) do |_svc, entries, **_kwargs|
      captured_bulk = entries.to_h do |e|
        [e[:measurement_point].register_template.group_role, e[:value]]
      end
      { success: true, results: {} }
    end

    captured_trigger = nil
    allow(ModbusWriteService).to receive(:write!) do |mp, value, **_kwargs|
      captured_trigger = [mp.register_template.group_role, value]
    end

    Timecop.freeze(Time.utc(2024, 3, 15, 14, 30, 25)) do
      behavior.sync_clock!
    end

    expect(captured_bulk).to eq(
      'seconds'      => 25,
      'minutes'      => 30,
      'hours'        => 14,
      'day_of_week'  => 5,
      'day_of_month' => 15,
      'month'        => 3,
      'year'         => 24
    )
    expect(captured_trigger).to eq(['upload_trigger', 1])
  end

  it 'no-ops and logs a warning when the upload trigger register is missing' do
    clock_mps.find { |mp| mp.register_template.group_role == 'upload_trigger' }.destroy

    expect_any_instance_of(ModbusWriteService).not_to receive(:bulk_write!)
    expect(ModbusWriteService).not_to receive(:write!)
    expect(Rails.logger).to receive(:warn).with(/missing clock registers/)

    behavior.sync_clock!
  end

  it 'no-ops and logs a warning when more than one role is missing' do
    clock_mps.find { |mp| mp.register_template.group_role == 'year'  }.destroy
    clock_mps.find { |mp| mp.register_template.group_role == 'month' }.destroy

    expect_any_instance_of(ModbusWriteService).not_to receive(:bulk_write!)
    expect(Rails.logger).to receive(:warn).with(/missing clock registers/)

    behavior.sync_clock!
  end
end
