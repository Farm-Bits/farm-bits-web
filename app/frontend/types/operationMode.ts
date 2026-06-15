export const OM_GROUPS = {
  status: 'om_status',
  manual: 'om_manual',
  dutyCycle: 'om_duty_cycle',
  sensor: 'om_sensor',
  sensorCondition: 'om_sensor_cond',
  schedule: 'om_schedule',
  window: 'om_window',
  safety: 'om_safety',
} as const;
export type OmGroupName = typeof OM_GROUPS[keyof typeof OM_GROUPS];
export type OmGroupPrefix = typeof OM_GROUPS.sensorCondition | typeof OM_GROUPS.schedule;
export type OmGroupNameOrSlot = OmGroupName | `${OmGroupPrefix}_${number}`;
export const OM_COMMAND_GROUPS = [OM_GROUPS.manual] as const;

export function isOmCommandGroup(groupName: string) {
  return OM_COMMAND_GROUPS.includes(groupName as typeof OM_COMMAND_GROUPS[number]);
}

export const OM_ROLES = {
  // Shared across multiple groups
  enabled: 'enabled',
  command: 'command',
  duration: 'duration',

  // Status
  activeSource: 'active_source',
  nextChangeTime: 'next_change_time',

  // Duty Cycle
  onDuration: 'on_duration',
  offDuration: 'off_duration',

  // Sensor Condition
  sourceType: 'source_type',
  sourceIoNumber: 'source_io_number',
  operator: 'operator',
  threshold: 'threshold',
  hysteresis: 'hysteresis',

  // Schedule
  startRef: 'start_ref',
  startTime: 'start_time',
  startOffset: 'start_offset',
  days: 'days',
  onetimeDay: 'onetime_day',
  onetimeMonth: 'onetime_month',
  onetimeYear: 'onetime_year',

  // Window
  endRef: 'end_ref',
  endTime: 'end_time',
  endOffset: 'end_offset',

  // Safety
  emergencyStop: 'emergency_stop'
} as const;
export type OmRole = typeof OM_ROLES[keyof typeof OM_ROLES];

export function isOmGroup(groupName: string): groupName is OmGroupNameOrSlot {
  const exactValues = Object.values(OM_GROUPS) as string[];
  if (exactValues.includes(groupName))
    return true;


  return /^om_schedule_\d+$/.test(groupName) ||
    /^om_sensor_cond_\d+$/.test(groupName);
}
