import { type Plc } from './plc';

export type Gateway = {
  id: number;
  label: string;
  name: string;
  imei: string;
  iccid: string | null;
  phone_number: string | null;
  private_ip: string;
};

export type GatewayAssigned = Gateway & {
  plcs: Plc[];
};
