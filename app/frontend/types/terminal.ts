import { type Plc } from './plc';

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
