export type AlertSeverity = 'info' | 'warning' | 'critical';
export type AlertConditionType = 'status_change' | 'threshold' | 'inactivity';
export type AlertDirection = 'to_on' | 'to_off' | 'both' | 'above' | 'below' | null;
export type AlertChannel = 'email' | 'push';
export type AlertScopeType = 'Company' | 'Site' | 'Plc' | 'MeasurementPoint' | 'AlertRule';

export interface Alert {
  id: number;
  rule_name: string;
  severity: AlertSeverity;
  condition_type: AlertConditionType;
  direction: AlertDirection;
  threshold_value: number | null;
  inactivity_seconds: number | null;
  min_duration_seconds: number | null;
  measurement_point_name: string;
  segment_name: string;
  unit: string | null;
  started_value: string | null;
  ended_value: string | null;
  measurement_point_id: number | null;
  alert_rule_id: number | null;
  site_id: number | null;
  started_at: string;
  ended_at: string | null;
  open: boolean;
  duration_seconds: number;
}

export interface AlertRule {
  id: number;
  name: string;
  severity: AlertSeverity;
  condition_type: AlertConditionType;
  direction: AlertDirection;
  threshold_value: number | null;
  inactivity_seconds: number | null;
  min_duration_seconds: number | null;
  active: boolean;
  measurement_point_id: number;
  measurement_point_name?: string;
  segment_name?: string;
  unit?: string | null;
  value_format?: string;
}

export interface AlertSubscription {
  id: number;
  scope_type: AlertScopeType;
  scope_id: number;
  scope_label: string;
  user_id: number;
  user_name?: string;
  user_email?: string;
  channels: AlertChannel[];
  min_severity: AlertSeverity;
  active: boolean;
}

export interface MeasurementPointOption {
  id: number;
  name: string;
  segment_name: string | null;
  unit: string | null;
  value_format: string;
}

export interface ScopeOption {
  id: number;
  name: string;
  site_id?: number;
  plc_id?: number;
  measurement_point_id?: number;
}

export interface ScopeOptionsPayload {
  company: { id: number; name: string };
  sites: ScopeOption[];
  plcs: ScopeOption[];
  measurement_points: ScopeOption[];
  alert_rules: ScopeOption[];
}
