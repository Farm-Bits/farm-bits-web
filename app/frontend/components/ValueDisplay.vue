<template>
  <div class="value-display">
    <span v-if="rawValue === null" class="text-muted">
      —
    </span>

    <CBadge
      v-else-if="valueFormat === 'boolean'"
      :color="booleanBadgeColor"
      :class="['status-badge', alarmClass]"
      :title="alarmTooltip">
      {{ displayValue }}
    </CBadge>

    <CTooltip v-else :content="alarmTooltip">
      <template #toggler="{ on }">
        <span v-on="on" :class="['value', alarmClass]">
          {{ displayValue }}
        </span>
      </template>
    </CTooltip>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import { getDisplayValue } from '@/utils/valueConverters.ts';
  import type { ValueFormat } from '@/types/plc';

  const {
    rawValue,
    valueFormat,
    unit,
    enumValues,
    alarmLow,
    alarmHigh,
    warningLow,
    warningHigh
  } = defineProps<{
    rawValue: string | number | null;
    valueFormat: ValueFormat;
    unit?: string | null;
    enumValues?: Record<string, string> | null;
    alarmLow?: number | null;
    alarmHigh?: number | null;
    warningLow?: number | null;
    warningHigh?: number | null;
  }>();

  const displayValue = computed(() => {
    return getDisplayValue(rawValue, valueFormat, {
      unit: unit,
      enumValues: enumValues
    });
  });

  const booleanBadgeColor = computed(() => {
    if (valueFormat === 'boolean') {
      const value = typeof rawValue === 'number' ? rawValue : Number(rawValue);
      return !!value ? 'success' : 'secondary';
    }

    return 'secondary';
  });

  const numericalValue = computed(() => {
    if (typeof rawValue === 'number')
      return rawValue;

    const parsed = parseFloat(String(rawValue));
    return isNaN(parsed) ? null : parsed;
  });

  const alarmClass = computed(() => {
    if (numericalValue.value === null)
      return '';

    if (alarmLow !== null && alarmLow !== undefined && numericalValue.value < alarmLow)
      return 'alarm-low';

    if (alarmHigh !== null && alarmHigh !== undefined && numericalValue.value > alarmHigh)
      return 'alarm-high';

    if (warningLow !== null && warningLow !== undefined && numericalValue.value < warningLow)
      return 'warning-low';

    if (warningHigh !== null && warningHigh !== undefined && numericalValue.value > warningHigh)
      return 'warning-high';

    return 'normal';
  });

  const alarmTooltip = computed(() => {
    if (typeof rawValue !== 'number')
      return '';

    if (alarmLow !== null && alarmLow !== undefined && rawValue < alarmLow)
      return `Alarm: Value ${rawValue} below threshold ${alarmLow}`;

    if (alarmHigh !== null && alarmHigh !== undefined && rawValue > alarmHigh)
      return `Alarm: Value ${rawValue} above threshold ${alarmHigh}`;

    if (warningLow !== null && warningLow !== undefined && rawValue < warningLow)
      return `Warning: Value ${rawValue} below threshold ${warningLow}`;

    if (warningHigh !== null && warningHigh !== undefined && rawValue > warningHigh)
      return `Warning: Value ${rawValue} above threshold ${warningHigh}`;

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

  .value.normal {
    color: var(--cui-body-color);
  }

  .alarm-low,
  .alarm-high {
    color: #dc3545;
    font-weight: 700;
  }

  .warning-low,
  .warning-high {
    color: #fd7e14;
    font-weight: 700;
  }

  .status-badge.alarm-low,
  .status-badge.alarm-high {
    border: 2px solid #dc3545;
  }

  .status-badge.warning-low,
  .status-badge.warning-high {
    border: 2px solid #fd7e14;
  }
</style>
