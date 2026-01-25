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

const CHART_TYPES = ['line', 'spline', 'areaspline', 'bar', 'state'] as const;
export type ChartType = typeof CHART_TYPES[number];
export function isChartType(chartType: unknown): chartType is ChartType {
  return CHART_TYPES.includes(chartType as ChartType);
}

export type MeasurementSubtype = {
  id: number;
  name: string;
  full_name: string;
  data_category: DataCategory;
  value_type: 'accumulative' | 'instantaneous' | 'status';
  default_unit: string;
  default_chart_type: ChartType;
  default_color: string | null;
  measurement_type: MeasurementType;
};

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

