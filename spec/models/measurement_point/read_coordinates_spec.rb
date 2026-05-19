require 'rails_helper'

# Tests that MeasurementPoint#read_coordinates produces the right wire-level
# address information for each topology.

RSpec.describe MeasurementPoint, '#read_coordinates' do
  context 'when the MP belongs to a PLC (PLC-native)' do
    # IMPORTANT ordering note:
    # The Plc has an after_create callback that auto-creates an MP for every
    # template that exists on its firmware at the moment of creation. So we
    # force the plc to be created BEFORE any templates exist — that way no
    # auto-MPs collide with the ones we create explicitly below.
    let(:gateway)   { create(:gateway) }
    let!(:firmware) { create(:modbus_firmware_version) }
    let!(:plc) do
      create(
        :plc,
        gateway:                 gateway,
        modbus_firmware_version: firmware,
        private_ip:              '192.168.1.10',
        slave_id:                1
      )
    end
    let(:template) do
      create(
        :register_template,
        modbus_firmware_version: firmware,
        address:                 100,
        address_count:           2,
        register_type:           'holding'
      )
    end
    let(:mp) { create(:measurement_point, plc: plc, register_template: template) }

    it 'resolves to the PLC directly' do
      coords = mp.read_coordinates

      expect(coords).not_to be_nil
      expect(coords.gateway).to eq(gateway)
      expect(coords.target_ip).to eq('192.168.1.10')
      expect(coords.slave_id).to eq(1)
      expect(coords.register_type).to eq('holding')
      expect(coords.count).to eq(2)
    end

    it 'uses the template address (with firmware address_offset = 0)' do
      # Factory's address_offset is 0; whatever global offset the codebase
      # applies is on top of that. With a freshly-built firmware, this
      # should match the template's address exactly.
      coords = mp.read_coordinates
      expect(coords.address).to eq(100)
    end
  end

  context 'when the MP belongs to a peripheral hosted by a PLC (relay topology)' do
    let(:gateway) { create(:gateway) }

    let!(:host_firmware)       { create(:modbus_firmware_version, :host_capable) }
    let!(:peripheral_firmware) { create(:modbus_firmware_version, :for_modbus_device) }

    let!(:compatibility) do
      create(
        :modbus_firmware_compatibility,
        host_version: host_firmware,
        peripheral_version: peripheral_firmware,
        firmware_code: 1
      )
    end

    # Force the host_plc and device to be created BEFORE any peripheral
    # templates exist (same reason as the PLC-native context above).
    let!(:host_plc) do
      create(
        :plc,
        gateway: gateway,
        modbus_firmware_version: host_firmware,
        private_ip: '192.168.1.10',
        slave_id: 1
      )
    end

    let!(:device) do
      create(
        :modbus_device,
        plc: host_plc,
        modbus_firmware_version: peripheral_firmware,
        slot_number: 2
      )
    end

    let(:template) do
      create(
        :register_template,
        modbus_firmware_version: peripheral_firmware,
        address: 100,
        address_count: 1
      )
    end

    let!(:read_mapping) do
      # template is created here (lazy reference), AFTER device, so no
      # collision with device's auto-create-MPs callback.
      create(
        :modbus_firmware_relay_mapping,
        modbus_firmware_version: host_firmware,
        register_template: template,
        relay_offset: 50,
        direction: 'read'
      )
    end

    let(:mp) { create(:measurement_point, modbus_device: device, plc: nil, register_template: template) }

    it "uses the HOST PLC's IP and slave_id, not the peripheral's" do
      coords = mp.read_coordinates
      expect(coords.target_ip).to eq(host_plc.private_ip)
      expect(coords.slave_id).to eq(host_plc.slave_id)
    end

    it "uses the host firmware's relay register type" do
      coords = mp.read_coordinates
      expect(coords.register_type).to eq('holding')
    end

    it 'resolves to base + size*(slot - 1) + offset' do
      coords = mp.read_coordinates
      # 8968 + 1200 * (2 - 1) + 50 = 10218
      expect(coords.address).to eq(10218)
    end

    it 'returns nil when no read mapping exists' do
      read_mapping.destroy
      expect(mp.reload.read_coordinates).to be_nil
    end
  end
end
