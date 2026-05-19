require 'rails_helper'

# Tests that MeasurementPoint#write_coordinates produces the right
# wire-level address information for writing, across all topologies.
#
# Write coordinates differ from read coordinates in one important way:
# for relay topology, the *write* relay offset can differ from the
# *read* relay offset within the same slot.

RSpec.describe MeasurementPoint, '#write_coordinates' do
  context 'when the MP belongs to a PLC (PLC-native)' do
    let(:gateway)   { create(:gateway) }
    let!(:firmware) { create(:modbus_firmware_version) }
    let!(:plc) do
      create(
        :plc,
        gateway: gateway,
        modbus_firmware_version: firmware,
        private_ip: '192.168.1.10',
        slave_id: 1
      )
    end
    let(:template) do
      create(
        :register_template,
        modbus_firmware_version: firmware,
        address: 200,
        register_type: 'holding',
        read_only: false
      )
    end
    let(:mp) { create(:measurement_point, plc: plc, register_template: template) }

    it 'resolves to the PLC directly' do
      coords = mp.write_coordinates

      expect(coords.target_ip).to eq('192.168.1.10')
      expect(coords.slave_id).to eq(1)
      expect(coords.register_type).to eq('holding')
      expect(coords.address).to eq(200)
    end

    it 'returns nil for a read-only register' do
      template.update!(read_only: true)
      expect(mp.write_coordinates).to be_nil
    end
  end

  context 'when the MP belongs to a peripheral hosted by a PLC (relay topology)' do
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

    let!(:host_plc) do
      create(
        :plc,
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
        read_only: false
      )
    end

    let!(:read_mapping) do
      create(
        :modbus_firmware_relay_mapping,
        modbus_firmware_version: host_firmware,
        register_template: template,
        relay_offset: 50,
        direction: 'read'
      )
    end

    let!(:write_mapping) do
      create(
        :modbus_firmware_relay_mapping,
        modbus_firmware_version: host_firmware,
        register_template: template,
        relay_offset: 70,
        direction: 'write'
      )
    end

    let(:mp) { create(:measurement_point, modbus_device: device, plc: nil, register_template: template) }

    it "routes through the HOST PLC's IP and slave_id" do
      coords = mp.write_coordinates
      expect(coords.target_ip).to eq(host_plc.private_ip)
      expect(coords.slave_id).to eq(host_plc.slave_id)
    end

    it 'uses the write-direction relay offset, not the read offset' do
      coords = mp.write_coordinates
      # 8968 + 1200 * (2 - 1) + 70 = 10238 (write offset)
      # vs. read would be 10218 (read offset = 50)
      expect(coords.address).to eq(10238)
    end

    it 'returns nil when no write mapping exists (read-only relay)' do
      write_mapping.destroy
      expect(mp.reload.write_coordinates).to be_nil
    end
  end
end
