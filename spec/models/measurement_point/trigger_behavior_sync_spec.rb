require 'rails_helper'

# When an MP's tracked fields change (e.g., `active`), the after_update
# callback should resolve the governing behavior and call the registered
# mp_trigger method.

RSpec.describe MeasurementPoint, '#trigger_behavior_sync' do
  # When MP#active flips false->true, the model ALSO fires sync_read!
  # via the after_update :sync_read_after_enable callback. That hits
  # VpnManagerClient, which doesn't work in tests. Stub it out so this
  # spec stays focused on the mp_trigger behavior.
  before do
    allow_any_instance_of(MeasurementPoint).to receive(:sync_read!).and_return(true)
  end

  let!(:firmware) { create(:modbus_firmware_version, :standard_v1) }
  let!(:plc)      { create(:plc, modbus_firmware_version: firmware) }
  let(:template) do
    create(:register_template,
      modbus_firmware_version: firmware,
      category:                'configuration')
  end
  let(:mp) { create(:measurement_point, plc: plc, register_template: template, active: false) }

  it 'fires sync_io_active! on the governing behavior when `active` changes' do
    expect_any_instance_of(ModbusBehaviors::StandardV1).to receive(:sync_io_active!)
    mp.update!(active: true)
  end

  it 'does NOT fire when an unrelated field changes' do
    expect_any_instance_of(ModbusBehaviors::StandardV1).not_to receive(:sync_io_active!)
    mp.update!(name: 'Renamed')
  end

  it 'does NOT fire when the PLC has no gateway' do
    plc.update_column(:gateway_id, nil)
    expect_any_instance_of(ModbusBehaviors::StandardV1).not_to receive(:sync_io_active!)
    mp.update!(active: true)
  end

  it 'does nothing on a firmware with no behavior profile' do
    no_behavior_firmware = create(:modbus_firmware_version)
    other_plc = create(:plc, modbus_firmware_version: no_behavior_firmware)
    other_template = create(
      :register_template,
      modbus_firmware_version: no_behavior_firmware,
      category: 'configuration'
    )
    other_mp = create(
      :measurement_point,
      plc: other_plc,
      register_template: other_template,
      active: false
    )

    expect { other_mp.update!(active: true) }.not_to raise_error
  end
end
