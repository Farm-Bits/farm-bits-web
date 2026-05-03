export type DeviceKind = 'gateway' | 'plc' | 'modbus_device';
export type DeviceStatus = 'online' | 'offline' | 'awaiting_setup' | 'disabled';

export type ModelSummary = {
  id: number;
  name: string;
  full_name: string;
  display_type: string | null;
  device_type: 'gateway' | 'plc' | 'modbus_device';
};

export type FirmwareSummary = {
  id: number;
  name: string;
  version_code: string;
};

export type GatewayDetails = {
  label: string;
  imei: string;
  iccid: string | null;
  phone_number: string | null;
  private_ip: string;
  serial_number: string;
  model: ModelSummary | null;
};

export type PlcDetails = {
  label: string;
  slave_id: number;
  private_ip: string;
  serial_number: string;
  gateway_id: number | null;
  model: ModelSummary | null;
  modbus_firmware_version: FirmwareSummary | null;
};

export type ModbusDeviceDetails = {
  label: string | null;
  slave_id: number;
  private_ip: string | null;
  slot_number: number | null;
  gateway_id: number | null;
  plc_id: number | null;
  host_kind: 'gateway' | 'plc' | null;
  model: ModelSummary | null;
  modbus_firmware_version: FirmwareSummary | null;
};

type DeviceRowBase = {
  row_key: string;
  id: number;
  name: string;
  display_type: string;
  status: DeviceStatus;
  last_seen_at: string | null;
  active: boolean;
};

export type GatewayRow = DeviceRowBase & {
  kind: 'gateway';
  details: GatewayDetails;
  children: Array<PlcRow | ModbusDeviceRow>;
};

export type PlcRow = DeviceRowBase & {
  kind: 'plc';
  details: PlcDetails;
  children: ModbusDeviceRow[];
};

export type ModbusDeviceRow = DeviceRowBase & {
  kind: 'modbus_device';
  details: ModbusDeviceDetails;
  children: never[];
};

export type DeviceRow = GatewayRow | PlcRow | ModbusDeviceRow;

type FlatExtras = {
  depth: number;
  is_last_child: boolean;
  ancestor_lines: boolean[];
};

export type FlatGatewayRow      = GatewayRow      & FlatExtras;
export type FlatPlcRow          = PlcRow          & FlatExtras;
export type FlatModbusDeviceRow = ModbusDeviceRow & FlatExtras;

export type FlatDeviceRow = FlatGatewayRow | FlatPlcRow | FlatModbusDeviceRow;

// ── Add Device modal options ─────────────────────────────────────────

export type AddDeviceModelOption = {
  id: number;
  name: string;
  full_name: string;
  display_type: string | null;
  supports_modbus_tcp: boolean;
  supports_modbus_rtu: boolean;
  firmware_versions: Array<{
    id: number;
    name: string;
    version_code: string;
    is_latest: boolean;
  }>;
};

export type EligibleHost = {
  kind: 'gateway' | 'plc';
  id: number;
  name: string;
  label: string;
  firmware_version_id?: number;
  supports_modbus_tcp: boolean;
  supports_modbus_rtu: boolean;
};

export type AddDeviceOptions = {
  models: AddDeviceModelOption[];
  hosts: {
    gateways: EligibleHost[];
    plcs: EligibleHost[];
  };
  compatibility: Record<string, number[]>;
};
