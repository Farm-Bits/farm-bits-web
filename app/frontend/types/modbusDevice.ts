import type { ModbusFirmwareVersion, RegisterMapping } from './plc';

type Manufacturer = {
  id: number;
  name: string;
};

type Model = {
  id: number;
  name: string;
  full_name: string;
  display_type: string;
  device_type: 'gateway' | 'plc' | 'modbus_device';
  manufacturer: Manufacturer;
};

export type ModbusDevice = {
  id: number;
  name: string;
  label: string | null;
  slave_id: number;
  private_ip: string | null;
  slot_number: number | null;
  active: boolean;
  last_seen_at: string | null;
  model: Model;
  modbus_firmware_version: ModbusFirmwareVersion;
};

export type ModbusDeviceWithRegisters = ModbusDevice & {
  register_mappings: RegisterMapping[];
};
