import { type MeasurementPoint, type MeasurementSubtype, type ValueType } from './measurementPoint';
import type { CommunicationType, Plc, RegisterMapping, RegisterTemplate, SourceIoInfo } from './plc';
import type { ModbusDevice } from './modbusDevice';
import type { OmGroupNameOrSlot } from './operationMode';

export type LiveMeasurementPoint = MeasurementPoint & {
  measurement_subtype: MeasurementSubtype | null;
  plc_id: Plc['id'] | null;
  modbus_device_id: ModbusDevice['id'] | null;
  device_owner_name: string | null;
  register_template: RegisterTemplate;
  interface_communication_type: CommunicationType | null;
  interface_io_number: number | null;
};

export type RawValue = {
  id: number;
  value: number;
  sample_time: string;
  measurement_point_id: MeasurementPoint['id'];
};

export type HourlyAggregation = {
  id: number;
  hour_timestamp: string;
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

export type AggregationLevel = 'hourly' | 'raw';

export type OperationModeConfigResponse = {
  register_mappings: RegisterMapping[];
  group_labels: Record<OmGroupNameOrSlot | string, string>;
  available_sources: SourceIoInfo[];
};
