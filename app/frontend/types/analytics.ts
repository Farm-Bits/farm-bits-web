import { type Segment } from './location';
import { type MeasurementPoint, type MeasurementSubtype, type ValueType } from './measurementPoint';

export type LiveMeasurementPoint = MeasurementPoint & {
  measurement_subtype: MeasurementSubtype | null;
  segment: Segment;
  plc_name: string;
  register_name: string;
};

export type RawValue = {
  id: number;
  value: number;
  scaled_value: number;
  sample_time: string;
  measurement_point_id: MeasurementPoint['id'];
};

export type HourlyAggregation = {
  id: number;
  date: string;
  hour: number;
  value_type: ValueType;
  reading_count: number;
  first_reading_at: string;
  last_reading_at: string;

  // Accumulative
  start_value: number | null;
  end_value: number | null;
  delta: number | null;

  // Instantaneous
  min_value: number | null;
  max_value: number | null;
  avg_value: number | null;
  sum_value: number | null;

  // Status
  time_on_seconds: number | null;
  time_off_seconds: number | null;
  transition_count: number | null;

  measurement_point_id: MeasurementPoint['id'];
};

type InstantaneousSummary = {
  measurement_point_id: MeasurementPoint['id'];
  value_type: 'instantaneous';
  min_value: number | null;
  max_value: number | null;
  avg_value: number | null;
  reading_count: number;
};

type AccumulativeSummary = {
  measurement_point_id: MeasurementPoint['id'];
  value_type: 'accumulative';
  start_value: number | null;
  end_value: number | null;
  total_delta: number | null;
  reading_count: number;
};

type StatusSummary = {
  measurement_point_id: MeasurementPoint['id'];
  value_type: 'status';
  total_time_on_seconds: number | null;
  total_time_off_seconds: number | null;
  on_percentage: number | null;
  total_transitions: number | null;
  reading_count: number;
};

export type AnalyticsSummary = InstantaneousSummary | AccumulativeSummary | StatusSummary;

export type PollResponse = {
  measurement_points: {
    id: MeasurementPoint['id'];
    last_value: number | string | null;
    last_value_at: string | null;
    alarm_state: MeasurementPoint['alarm_state'];
  }[];
};

export type MeasurementPointGroup = {
  key: string;
  label: string;
  measurementPoints: LiveMeasurementPoint[];
};

export type AggregationLevel = 'hourly' | 'raw';
