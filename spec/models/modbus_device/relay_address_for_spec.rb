require 'rails_helper'

# Tests the relay address math directly on ModbusDevice.
#
# Formula: host.relay_slot_base + host.relay_slot_size * (device.slot_number - 1) + mapping.relay_offset

RSpec.describe ModbusDevice, '#relay_address_for' do
  let(:host_firmware)       { create(:modbus_firmware_version, :host_capable) }
  let(:peripheral_firmware) { create(:modbus_firmware_version, :for_modbus_device) }

  let!(:compatibility) do
    create(
      :modbus_firmware_compatibility,
      host_version: host_firmware,
      peripheral_version: peripheral_firmware,
      firmware_code: 1
    )
  end

  let(:host_plc) { create(:plc, modbus_firmware_version: host_firmware) }

  let(:template) do
    create(:register_template, modbus_firmware_version: peripheral_firmware)
  end

  context 'with a read mapping at offset 50' do
    let(:device) do
      create(
        :modbus_device,
        plc: host_plc,
        modbus_firmware_version: peripheral_firmware,
        slot_number: 3
      )
    end

    before do
      create(
        :modbus_firmware_relay_mapping,
        modbus_firmware_version: host_firmware,
        register_template: template,
        relay_offset: 50,
        direction: 'read'
      )
    end

    it 'returns base + slot_size * (slot - 1) + offset' do
      # 8968 + 1200 * 2 + 50 = 11418
      expect(device.relay_address_for(template, direction: 'read')).to eq(11418)
    end
  end

  context 'with separate read and write mappings' do
    let(:device) do
      create(
        :modbus_device,
        plc: host_plc,
        modbus_firmware_version: peripheral_firmware,
        slot_number: 1
      )
    end

    before do
      create(
        :modbus_firmware_relay_mapping,
        modbus_firmware_version: host_firmware,
        register_template: template,
        relay_offset: 50,
        direction: 'read'
      )
      create(
        :modbus_firmware_relay_mapping,
        modbus_firmware_version: host_firmware,
        register_template: template,
        relay_offset: 70,
        direction: 'write'
      )
    end

    it 'returns the read offset for read direction' do
      # 8968 + 1200 * 0 + 50 = 9018
      expect(device.relay_address_for(template, direction: 'read')).to eq(9018)
    end

    it 'returns the write offset for write direction' do
      # 8968 + 1200 * 0 + 70 = 9038
      expect(device.relay_address_for(template, direction: 'write')).to eq(9038)
    end
  end

  context 'when the host firmware is not host-capable' do
    let(:bare_host_firmware) { create(:modbus_firmware_version) }
    let(:bare_host_plc)      { create(:plc, modbus_firmware_version: bare_host_firmware) }
    let(:device) do
      build(
        :modbus_device,
        plc: bare_host_plc,
        modbus_firmware_version: peripheral_firmware,
        slot_number: 1
      )
    end

    it 'returns nil' do
      expect(device.relay_address_for(template, direction: 'read')).to be_nil
    end
  end

  context 'when no relay mapping exists for the template' do
    let(:device) do
      create(
        :modbus_device,
        plc: host_plc,
        modbus_firmware_version: peripheral_firmware,
        slot_number: 1
      )
    end

    it 'returns nil' do
      expect(device.relay_address_for(template, direction: 'read')).to be_nil
    end
  end

  context 'when the device is not connected to a host PLC (gateway-direct)' do
    let(:device) { create(:modbus_device, :gateway_direct, modbus_firmware_version: peripheral_firmware) }

    it 'returns nil regardless of mappings' do
      create(
        :modbus_firmware_relay_mapping,
        modbus_firmware_version: host_firmware,
        register_template:       template,
        relay_offset:            50,
        direction:               'read'
      )

      expect(device.relay_address_for(template, direction: 'read')).to be_nil
    end
  end
end
