import { type DataCategory, type MeasurementPoint } from './measurementPoint';

const COMMUNICATION_TYPES = ['analog_input', 'analog_output', 'digital_input', 'digital_output'] as const;
export type CommunicationType = typeof COMMUNICATION_TYPES[number];

const INTERFACE_CATEGORIES = ['status', 'analog', 'counter', 'interface_configuration', 'interface_status', 'operation_mode_configuration', 'operation_mode_status'] as const;
type InterfaceCategory = typeof INTERFACE_CATEGORIES[number];

export function isConfigurationCategory(category: string) {
  return ['interface_configuration'].includes(category);
}

const VALUE_FORMATS = ['numeric', 'boolean', 'enum', 'ascii_string', 'time_of_day', 'duration_seconds', 'bitmask'] as const;
export type ValueFormat = typeof VALUE_FORMATS[number];

type DataType =
  | 'int8' | 'uint8'
  | 'int16' | 'uint16'
  | 'int32' | 'uint32'
  | 'int64' | 'uint64'
  | 'float32' | 'float64'
  | 'boolean' | 'string';

/**
 * Visibility conditions for conditional display of configuration fields.
 * Keys are group_role names of controller registers.
 * Values are the expected values (or array of values) that make this field visible.
 *
 * Example:
 * {
 *   "input_type_selector": ["3", "11"]  // Visible when input type is 4-20mA or 0-20mA
 * }
 */
type VisibilityConditions = Record<string, string | string[]>;

/**
 * Validation rules for cross-field validation within a group.
 */
export type ValidationRules = {
  /** Field is required when another field has a specific value */
  required_when?: {
    group_role: string;
    equals?: string | number;
    not_equals?: string | number;
  };

  /** Field is required when any of the specified conditions are met */
  required_when_any?: {
    group_role: string;
    equals?: string | number;
    not_equals?: string | number;
  }[];

  /** At least one of these roles must have a value */
  one_of_required?: string[];

  /** This value must be less than the value of another field */
  less_than?: {
    group_role: string;
  };

  /** This value must be greater than the value of another field */
  greater_than?: {
    group_role: string;
  };

  /** Custom validation message */
  message?: string;
};

export type RegisterTemplate = {
  id: number;
  name: string;
  label: string;
  description: string | null;
  address_count: number;
  data_type: DataType;
  value_format: ValueFormat;
  factor: number;
  offset: number;
  category: InterfaceCategory | 'configuration' | 'diagnostic';
  group_name: string | null;
  group_role: string | null;
  validation_rules: ValidationRules | null;
  visibility_conditions: VisibilityConditions | null;
  read_only: boolean;
  min_value: number | null;
  max_value: number | null;
  default_value: string | null;
  enum_values: Record<string, string> | null;
  position: number;
};

export type Interface = {
  id: number;
  name: string;
  communication_type: CommunicationType;
  description: string | null;
  io_number: number;
  data_categories: DataCategory[];
};

export type RegisterMapping = {
  register_template: RegisterTemplate;
  measurement_point: MeasurementPoint;
  position: number;
};

export type InterfaceWithMeasurementPoints = Interface & {
  register_mappings: RegisterMapping[];
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
  slave_id: number;
  private_ip: string | null;
  last_seen_at: string | null;
  plc_version: PlcVersion;
};

export type PlcWithInterfaces = Plc & {
  interfaces: InterfaceWithMeasurementPoints[];
  register_mappings: RegisterMapping[];
};

