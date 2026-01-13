import type { CommunicationType } from '@/types/plc';

export const COMMUNICATION_TYPE_TABS: {
  key: CommunicationType;
  label: string;
  icon: string;
}[] = [
  { key: 'digital_input', label: 'Digital Inputs', icon: 'cilToggleOn' },
  { key: 'digital_output', label: 'Digital Outputs', icon: 'cilToggleOff' },
  { key: 'analog_input', label: 'Analog Inputs', icon: 'cilChartLine' },
  { key: 'analog_output', label: 'Analog Outputs', icon: 'cilSpeedometer' },
];
