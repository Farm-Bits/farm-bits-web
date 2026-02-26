import type { MeasurementSubtype } from './measurementPoint';

export type WeatherStationApiRawValue = {
  id: number;
  sample_time: string;
  scaled_value: number | null;
};

export type WeatherStationApiHourlyAggregation = {
  id: number;
  date: string;
  hour: number;
  value: number | null;
  min_value: number | null;
  max_value: number | null;
  avg_value: number | null;
  sum_value: number | null;
  sample_count: number;
};

export type WeatherStationApiMetric = {
  id: number;
  key: string;
  label: string;
  effective_unit: string;
  aggregation: 'avg' | 'sum' | 'min' | 'max';
  measurement_subtype_id: MeasurementSubtype['id'];
  measurement_subtype: MeasurementSubtype;
};

export type SunData = {
  date: string;
  sunrise: string;
  sunset: string;
  civil_twilight_begin: string | null;
  civil_twilight_end: string | null;
  day_length_seconds: number | null;
};
