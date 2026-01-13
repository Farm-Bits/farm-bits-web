import { type DataCategory, type MeasurementPoint } from './measurementPoint';

const COMMUNICATION_TYPES = ['analog_input', 'analog_output', 'digital_input', 'digital_output'] as const;
export type CommunicationType = typeof COMMUNICATION_TYPES[number];

const INTERFACE_CATEGORIES = ['status', 'analog', 'counter', 'interface_configuration', 'measurement_point_configuration', 'operation_mode_configuration'] as const;
type InterfaceCategory = typeof INTERFACE_CATEGORIES[number];

const VALUE_FORMATS = ['numeric', 'boolean', 'enum', 'ascii_string'] as const;
export type ValueFormat = typeof VALUE_FORMATS[number];

export type RegisterTemplate = {
  id: number;
  name: string;
  label: string;
  description: string | null;
  value_format: ValueFormat;
  factor: number;
  offset: number;
  category: InterfaceCategory | 'configuration' | 'diagnostic';
  group_name: string | null;
  read_only: boolean;
  min_value: number | null;
  max_value: number | null;
  default_value: string | null;
  enum_values: Record<string, string> | null;
};

export type Interface = {
  id: number;
  name: string;
  communication_type: CommunicationType;
  description: string | null;
  position: number;
  data_categories: DataCategory[];
};

export type InterfaceWithMeasurementPoints = Interface & {
  register_mappings: {
    category: InterfaceCategory;
    register_template: RegisterTemplate;
    measurement_point: MeasurementPoint;
  }[];
};

type PlcVersion = {
  id: number;
  name: string;
  description: string | null;
  is_latest: boolean;
  is_supported: boolean;
};

export type Plc = {
  id: number;
  label: string;
  name: string;
  slave: number;
  private_ip: string | null;
  last_seen_at: string | null;
  plc_version: PlcVersion;
};

export type PlcWithInterfaces = Plc & {
  interfaces: InterfaceWithMeasurementPoints[];
};


// export type PlcShowResponse = {
//   plc: PlcWithInterfaces;
//   segments: Segment[];
//   measurementSubtypes: MeasurementSubtype[];
//   availableRegisterTemplates: RegisterTemplate[];
// };

// // ============================================
// // Configuration Register Types (non-interface)
// // ============================================

// export type ConfigurationRegister = MeasurementPoint & {
//   register_template: RegisterTemplate & {
//     category: 'configuration';
//   };
// };


// export const CHART_TYPES = ['line', 'spline', 'areaspline', 'bar', 'state'] as const;
// export type ChartType = typeof CHART_TYPES[number];
