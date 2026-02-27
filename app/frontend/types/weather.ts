import type { MeasurementSubtype, ValueType } from './measurementPoint';

export type SunData = {
  date: string;
  sunrise: string;
  sunset: string;
  civil_twilight_begin: string | null;
  civil_twilight_end: string | null;
  day_length_seconds: number | null;
};

export type WeatherStationApiRawValue = {
  id: number;
  value: number | null;
  sample_time: string;
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
  unit: string;
  measurement_subtype_id: MeasurementSubtype['id'];
  measurement_subtype: MeasurementSubtype;
};

export type WeatherStationApiSummary = {
  weather_station_api_metric_id: WeatherStationApiMetric['id'];
  value_type: ValueType;
  sample_count: number;
  min_value?: number | null;
  max_value?: number | null;
  avg_value?: number | null;
  sum_value?: number | null;
};
