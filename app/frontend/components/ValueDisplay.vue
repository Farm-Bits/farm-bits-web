<template>
  <div class="value-display">
    <!-- No Value -->
    <span v-if="valueToDisplay === null" class="text-muted">
      —
    </span>

    <!-- Boolean/Status Value -->
    <CBadge
      v-else-if="props.valueFormat === 'boolean'"
      :color="badgeColor"
      :class="['status-badge', alarmClass]"
      :title="alarmTooltip">
      {{ formattedValue }}
    </CBadge>

    <!-- Numeric/Enum/String Value -->
    <CTooltip v-else :title="alarmTooltip">
      <template #toggler="{ id, on }">
        <span v-on="on" :class="['value', alarmClass]">
          {{ formattedValue }}
        </span>
      </template>
    </CTooltip>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { ValueFormat } from '@/types/plc';

  const props = defineProps<{
    measurementPoint: MeasurementPoint;
    valueToDisplay: string | number | null;
    valueFormat: ValueFormat;
    enumValues?: Record<string, string> | null;
  }>();

  const formatters: Record<ValueFormat, (value: string | number | null) => string> = {
    numeric: (value) => {
      if (value === null)
        return '—';

      const numValue = typeof value === 'number' ? value : parseFloat(String(value));
      const formatted = Number.isInteger(numValue)
        ? numValue.toString()
        : numValue.toFixed(2);

      return `${formatted} ${props.measurementPoint.effective_unit}`;
    },
    boolean: (value) => {
      const options = props.measurementPoint.effective_unit.split('/');
      const index = typeof value === 'number' ? value : Number(value);

      if (isNaN(index) || index < 0 || index >= options.length)
        return `Server Configuration Error (${index})`;

      return options[index];
    },
    enum: (value) => {
      const key = String(value);
      return props.enumValues?.[key] ?? `Server Configuration Error (${key})`;
    },
    ascii_string: (value) => String(value ?? '—'),
    time_of_day: (value) => {
      if (value === null)
        return '—';

      if (typeof value === 'string' && value.includes(':'))
        return value;

      const totalMinutes = typeof value === 'number' ? value : parseInt(String(value), 10);
      if (isNaN(totalMinutes))
        return '—';

      const hours = Math.floor(totalMinutes / 60);
      const minutes = totalMinutes % 60;
      return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
    },
    duration_seconds: (value) => {
      if (value === null)
        return '—';

      if (typeof value === 'string' && value.includes(':'))
        return value;

      const totalSeconds = typeof value === 'number' ? value : parseInt(String(value), 10);
      if (isNaN(totalSeconds))
        return '—';

      const hours = Math.floor(totalSeconds / 3600);
      const minutes = Math.floor((totalSeconds % 3600) / 60);
      const seconds = totalSeconds % 60;

      if (hours > 0)
        return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
      return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    }
  };

  const formattedValue = computed(() =>
    formatters[props.valueFormat](props.valueToDisplay)
  );

  const badgeColor = computed(() => {
    if (props.valueFormat === 'boolean') {
      const value = typeof props.valueToDisplay === 'number' ? props.valueToDisplay : Number(props.valueToDisplay);
      return !!value ? 'success' : 'secondary';
    }

    return 'secondary';
  });

  const numValue = computed(() => {
    if (typeof props.valueToDisplay === 'number')
      return props.valueToDisplay;

    const parsed = parseFloat(String(props.valueToDisplay));
    return isNaN(parsed) ? null : parsed;
  });

  const alarmClass = computed(() => {
    if (numValue.value === null)
      return '';

    const { alarm_low, alarm_high, warning_low, warning_high } = props.measurementPoint;

    if (alarm_low !== null && numValue.value < alarm_low)
      return 'alarm-low';
    if (alarm_high !== null && numValue.value > alarm_high)
      return 'alarm-high';
    if (warning_low !== null && numValue.value < warning_low)
      return 'warning-low';
    if (warning_high !== null && numValue.value > warning_high)
      return 'warning-high';

    return 'normal';
  });

  const alarmTooltip = computed(() => {
    const val = props.valueToDisplay;
    if (typeof val !== 'number')
      return '';

    const { alarm_low, alarm_high, warning_low, warning_high } = props.measurementPoint;

    if (alarm_low !== null && val < alarm_low)
      return `Alarm: Value ${val} below threshold ${alarm_low}`;
    if (alarm_high !== null && val > alarm_high)
      return `Alarm: Value ${val} above threshold ${alarm_high}`;
    if (warning_low !== null && val < warning_low)
      return `Warning: Value ${val} below threshold ${warning_low}`;
    if (warning_high !== null && val > warning_high)
      return `Warning: Value ${val} above threshold ${warning_high}`;

    return '';
  });
</script>

<style scoped>
  .value-display {
    font-family: 'SF Mono', Monaco, Inconsolata, 'Fira Code', monospace;
    display: inline-flex;
    align-items: center;
  }

  .value {
    font-weight: 600;
    font-size: 0.9rem;
    transition: color 0.2s ease;
  }

  .status-badge {
    font-size: 0.75rem;
    padding: 0.25em 0.5em;
    transition: all 0.2s ease;
  }

  /* Normal state */
  .value.normal {
    color: var(--cui-body-color);
  }

  /* Alarm states */
  .alarm-low,
  .alarm-high {
    color: #dc3545;
    font-weight: 700;
  }

  /* Warning states */
  .warning-low,
  .warning-high {
    color: #fd7e14;
    font-weight: 700;
  }

  /* Apply alarm styling to badges */
  .status-badge.alarm-low,
  .status-badge.alarm-high {
    border: 2px solid #dc3545;
  }

  .status-badge.warning-low,
  .status-badge.warning-high {
    border: 2px solid #fd7e14;
  }
</style>
