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

export type MeasurementPointFormData = {
  name: string;
  description: string | null;
  unit_override: string | null;
  chart_type_override: string | null;
  color_override: string | null;
  factor_override: number | null;
  offset_override: number | null;
  alarm_low: number | null;
  alarm_high: number | null;
  warning_low: number | null;
  warning_high: number | null;
  active: boolean;
  measurement_subtype_id: number | null;
  segment_id: number | null;
};
