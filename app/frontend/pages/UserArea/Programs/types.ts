import type { RegisterMapping } from '@/types/plc';

export type ProgramPhase = {
  index: number;
  group_name: string;
  registers: RegisterMapping[];
};

export type ProgramMeta = {
  registers: RegisterMapping[];
};

export type Program = {
  index: number;
  phases: ProgramPhase[];
  meta: ProgramMeta | null;
};

export type ProgramSource = {
  kind: 'plc' | 'modbus_device';
  id: number;
  name: string;
  firmware: string | null;
};
