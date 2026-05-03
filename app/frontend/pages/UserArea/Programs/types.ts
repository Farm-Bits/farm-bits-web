import type { RegisterMapping } from '@/types/plc';

type Phase = {
  index: number;
  group_name: string;
  registers: RegisterMapping[];
};

type ProgramMeta = {
  group_name: string;
  registers: RegisterMapping[];
};

export type Program = {
  index: number;
  phases: Phase[];
  meta: ProgramMeta | null;
};
