<template>
  <span class="value-display" :class="rootClasses">
    <!-- Null / no data -->
    <span v-if="value === null || value === undefined" class="value-display__empty">
      {{ placeholder }}
    </span>

    <!-- Boolean: colored badge -->
    <CBadge
      v-else-if="valueFormat === 'boolean'"
      :color="booleanColor"
      class="value-display__badge"
      shape="rounded-pill">
      {{ booleanLabel }}
    </CBadge>

    <!-- Enum: label from enum_values map -->
    <template v-else-if="valueFormat === 'enum'">
      <span class="value-display__text">{{ enumLabel }}</span>
      <span v-if="unit" class="value-display__unit">{{ unit }}</span>
    </template>

    <!-- Numeric / time_of_day / duration_seconds / ascii_string -->
    <template v-else>
      <span class="value-display__number">{{ formattedValue }}</span>
      <span v-if="displayUnit" class="value-display__unit">{{ displayUnit }}</span>
    </template>
  </span>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import type { AlarmState } from '@/types/measurementPoint';
  import type { ValueFormat } from '@/types/plc';

  const props = withDefaults(defineProps<{
    value: string | number | null;
    valueFormat?: ValueFormat;
    unit?: string | null;
    enumValues?: Record<string, string> | null;
    alarmState?: AlarmState | null;
    placeholder?: string;
    /** Size variant: compact for tables/lists, default for cards, large for hero displays */
    size?: 'compact' | 'default' | 'large';
    /** Show the unit inline (default true) */
    showUnit?: boolean;
    /** Custom boolean labels [falsy, truthy] */
    booleanLabels?: [string, string];
  }>(), {
    valueFormat: 'numeric',
    unit: null,
    enumValues: null,
    alarmState: null,
    placeholder: '—',
    size: 'default',
    showUnit: true,
    booleanLabels: () => ['Off', 'On'],
  });

  // ── Computed: alarm/warning CSS class on root ──
  const rootClasses = computed(() => {
    const classes: string[] = [`value-display--${props.size}`];
    if (props.alarmState && props.alarmState !== 'normal')
      classes.push(`value-display--${props.alarmState}`);

    return classes;
  });

  // ── Boolean ──
  const booleanNumeric = computed(() => {
    if (typeof props.value === 'number')
      return props.value;

    return Number(props.value);
  });

  const booleanColor = computed(() => {
    if (props.alarmState === 'alarm_low' || props.alarmState === 'alarm_high')
      return 'danger';

    if (props.alarmState === 'warning_low' || props.alarmState === 'warning_high')
      return 'warning';

    return booleanNumeric.value ? 'success' : 'secondary';
  });

  const booleanLabel = computed(() => {
    // If enum_values are provided, use those as labels
    if (props.enumValues) {
      const key = String(booleanNumeric.value);
      return props.enumValues[key] ?? props.booleanLabels[booleanNumeric.value ? 1 : 0];
    }
    return props.booleanLabels[booleanNumeric.value ? 1 : 0];
  });

  // ── Enum ──
  const enumLabel = computed(() => {
    if (!props.enumValues)
      return String(props.value);

    const key = String(props.value);
    return props.enumValues[key] ?? `Unknown (${key})`;
  });

  // ── Numeric + special formats ──
  const formattedValue = computed(() => {
    const val = props.value;
    if (val === null || val === undefined)
      return '';

    switch (props.valueFormat) {
      case 'time_of_day':
        return formatTimeOfDay(val);
      case 'duration_seconds':
        return formatDuration(val);
      case 'ascii_string':
        return String(val);
      case 'numeric':
      default:
        return formatNumeric(val);
    }
  });

  const displayUnit = computed(() => {
    if (!props.showUnit || !props.unit)
      return null;

    // Don't show units for non-numeric formats
    if (props.valueFormat === 'time_of_day' || props.valueFormat === 'ascii_string')
      return null;

    return props.unit;
  });

  // ── Formatters ──
  function formatNumeric(val: string | number): string {
    const num = typeof val === 'number' ? val : parseFloat(String(val));
    if (isNaN(num))
      return String(val);

    // Determine appropriate decimal places based on magnitude
    if (Number.isInteger(num))
      return num.toLocaleString();

    if (Math.abs(num) >= 100)
      return Number(num.toFixed(1)).toLocaleString();

    if (Math.abs(num) >= 1)
      return Number(num.toFixed(2)).toLocaleString();

    return Number(num.toPrecision(3)).toLocaleString();
  }

  function formatTimeOfDay(val: string | number): string {
    const minutes = typeof val === 'number' ? val : parseInt(String(val), 10);
    if (isNaN(minutes) || minutes < 0 || minutes > 1439)
      return String(val);

    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
  }

  function formatDuration(val: string | number): string {
    const totalSeconds = typeof val === 'number' ? val : parseInt(String(val), 10);
    if (isNaN(totalSeconds) || totalSeconds < 0)
      return String(val);

    const h = Math.floor(totalSeconds / 3600);
    const m = Math.floor((totalSeconds % 3600) / 60);
    const s = totalSeconds % 60;

    if (h > 0)
      return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;

    return `${m}:${s.toString().padStart(2, '0')}`;
  }
</script>

<style scoped>
  .value-display {
    display: inline-flex;
    align-items: baseline;
    gap: 0.25rem;
    line-height: 1.2;
    transition: color 0.2s ease;
  }

  /* ── Size variants ── */
  .value-display--compact .value-display__number,
  .value-display--compact .value-display__text {
    font-size: 0.85rem;
    font-weight: 600;
  }

  .value-display--compact .value-display__unit {
    font-size: 0.7rem;
  }

  .value-display--default .value-display__number,
  .value-display--default .value-display__text {
    font-size: 1rem;
    font-weight: 700;
  }

  .value-display--default .value-display__unit {
    font-size: 0.875rem;
  }

  .value-display--large .value-display__number,
  .value-display--large .value-display__text {
    font-size: 2rem;
    font-weight: 700;
  }

  .value-display--large .value-display__unit {
    font-size: 1rem;
  }

  /* ── Number + Unit ── */
  .value-display__number {
    color: var(--cui-body-color, #111827);
    font-variant-numeric: tabular-nums;
  }

  .value-display__text {
    color: var(--cui-body-color, #111827);
  }

  .value-display__unit {
    color: var(--cui-tertiary-color, #6b7280);
    font-weight: 400;
  }

  .value-display__empty {
    color: var(--cui-tertiary-color, #9ca3af);
  }

  /* ── Badge ── */
  .value-display__badge {
    font-size: 0.80rem;
    padding: 0.25em 0.6em;
    letter-spacing: 0.02em;
  }

  .value-display--compact .value-display__badge {
    font-size: 0.7rem;
    padding: 0.2em 0.5em;
  }

  .value-display--large .value-display__badge {
    font-size: 0.85rem;
    padding: 0.3em 0.75em;
  }

  /* ── Alarm states ── */
  .value-display--alarm_low .value-display__number,
  .value-display--alarm_high .value-display__number,
  .value-display--alarm_low .value-display__text,
  .value-display--alarm_high .value-display__text {
    color: #dc3545;
    font-weight: 700;
  }

  .value-display--warning_low .value-display__number,
  .value-display--warning_high .value-display__number,
  .value-display--warning_low .value-display__text,
  .value-display--warning_high .value-display__text {
    color: #f59e0b;
    font-weight: 700;
  }

  .value-display--alarm_low .value-display__unit,
  .value-display--alarm_high .value-display__unit {
    color: #dc354580;
  }

  .value-display--warning_low .value-display__unit,
  .value-display--warning_high .value-display__unit {
    color: #f59e0b80;
  }

  /* ── Badge alarm borders ── */
  .value-display--alarm_low .value-display__badge,
  .value-display--alarm_high .value-display__badge {
    box-shadow: 0 0 0 2px #dc354540;
  }

  .value-display--warning_low .value-display__badge,
  .value-display--warning_high .value-display__badge {
    box-shadow: 0 0 0 2px #f59e0b40;
  }
</style>
