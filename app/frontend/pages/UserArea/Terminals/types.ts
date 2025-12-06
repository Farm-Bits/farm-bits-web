type PlcVersion = {
  id: number;
  name: string;
  description: string | null;
};

export type Plc = {
  id: number;
  label: string;
  name: string;
  slave: number;
  private_ip: string | null;
  plc_version: PlcVersion;
};

export type Terminal = {
  id: number;
  label: string;
  name: string;
  imei: string;
  iccid: string | null;
  phone_number: string | null;
  private_ip: string;
};

export type TerminalAssigned = Terminal & {
  plcs: Plc[];
};
