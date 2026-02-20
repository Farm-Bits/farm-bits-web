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
      {{ displayValue }}
    </CBadge>

    <!-- Enum: label from enum_values map -->
    <template v-else-if="valueFormat === 'enum'">
      <span class="value-display__text">{{ displayValue }}</span>
      <span v-if="unit" class="value-display__unit">{{ unit }}</span>
    </template>

    <!-- Numeric / time_of_day / duration_seconds / ascii_string -->
    <template v-else>
      <span class="value-display__number">{{ displayValue }}</span>
      <span v-if="displayUnit" class="value-display__unit">{{ displayUnit }}</span>
    </template>
  </span>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import { getDisplayValue } from '@/utils/valueConverters.ts';
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
    showUnit?: boolean;
  }>(), {
    valueFormat: 'numeric',
    unit: null,
    enumValues: null,
    alarmState: null,
    placeholder: '—',
    size: 'default',
    showUnit: true
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

  const displayValue = computed(() => {
    return getDisplayValue(props.value, props.valueFormat, {
      unit: props.unit,
      enumValues: props.enumValues,
      showUnit: false
    });
  });

  const displayUnit = computed(() => {
    if (!props.showUnit || !props.unit)
      return null;

    // Don't show units for non-numeric formats
    if (props.valueFormat === 'time_of_day' || props.valueFormat === 'ascii_string')
      return null;

    return props.unit;
  });
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
