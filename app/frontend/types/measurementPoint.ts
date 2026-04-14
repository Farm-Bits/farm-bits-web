import { type Segment } from './location';
import { type RegisterTemplate } from './plc';

export type MeasurementType = {
  id: number;
  name: string;
  position: number;
};

const DATA_CATEGORIES = ['status', 'analog', 'counter'] as const;
export type DataCategory = typeof DATA_CATEGORIES[number];
export function isDataCategory(category: unknown): category is DataCategory {
  return DATA_CATEGORIES.includes(category as DataCategory);
}

export const CHART_TYPES_BY_VALUE_TYPE = {
  instantaneous: ['line', 'area', 'bar'],
  accumulative:  ['line', 'area', 'bar'],
  status:        ['step', 'rangeBar'],
} as const;
export const CHART_TYPES = [
  ...new Set(Object.values(CHART_TYPES_BY_VALUE_TYPE).flat())
] as const;
export type ChartType = typeof CHART_TYPES_BY_VALUE_TYPE[ValueType][number];
export function isChartType(chartType: unknown): chartType is ChartType {
  return CHART_TYPES.includes(chartType as any);
}
export function isValidChartTypeForValueType(chartType: ChartType, valueType: ValueType): boolean {
  return (CHART_TYPES_BY_VALUE_TYPE[valueType] as readonly string[]).includes(chartType);
}

const VALUE_TYPES = ['accumulative', 'instantaneous', 'status'] as const;
export type ValueType = typeof VALUE_TYPES[number];
export function isValueType(valueType: unknown): valueType is ValueType {
  return VALUE_TYPES.includes(valueType as ValueType);
}

type ControlGroup = {
  id: number;
  name: string;
  icon_key: string | null;
  position: number;
};

export type MeasurementSubtype = {
  id: number;
  name: string;
  full_name: string;
  data_category: DataCategory;
  value_type: ValueType;
  default_unit: string;
  default_chart_type: ChartType;
  default_color: string | null;
  icon_key: string | null;
  position: number;
  measurement_type: MeasurementType;
  control_group: ControlGroup | null;
};

export type AlarmState = 'normal' | 'warning_low' | 'warning_high' | 'alarm_low' | 'alarm_high';

export type MeasurementPoint = {
  id: number;
  name: string;
  description: string | null;
  unit_override: string | null;
  chart_type_override: ChartType | null;
  color_override: string | null;
  // data_collection_enabled: boolean;
  // polling_interval_seconds: number | null;
  factor_override: number | null;
  offset_override: number | null;
  alarm_low: number | null;
  alarm_high: number | null;
  warning_low: number | null;
  warning_high: number | null;
  alarm_state: AlarmState | null;
  last_value: number | string | null;
  last_value_at: string | null;
  position: number;
  active: boolean;
  effective_unit: string | null;
  effective_chart_type: ChartType | null;
  effective_color: string | null;
  measurement_subtype_id: MeasurementSubtype['id'] | null;
  register_template_id: RegisterTemplate['id'];
  segment_id: Segment['id'] | null;
};
