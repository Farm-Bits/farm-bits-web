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

   <!-- Bitmask: badge list showing active/inactive bits -->
    <span v-else-if="valueFormat === 'bitmask' && enumValues" class="value-display__bitmask">
      <CBadge
        v-for="(label, bitStr) in enumValues"
        :key="bitStr"
        :color="isBitActive(Number(bitStr)) ? 'primary' : 'light'"
        :class="{ 'text-body-secondary': !isBitActive(Number(bitStr)) }"
        class="value-display__bitmask-badge">
        {{ label }}
      </CBadge>
    </span>

    <!-- Bitmask without enum_values: show comma-joined text -->
    <span v-else-if="valueFormat === 'bitmask'" class="value-display__text">
      {{ displayValue }}
    </span>

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
  import { getDisplayValue, valueConverters } from '@/utils/valueConverters';
  import { useNow } from '@/composables/useNow';
  import type { ValueFormat } from '@/types/plc';

  const props = withDefaults(defineProps<{
    value: string | number | null;
    valueFormat?: ValueFormat;
    unit?: string | null;
    enumValues?: Record<string, string> | null;
    placeholder?: string;
    /** Size variant: compact for tables/lists, default for cards, large for hero displays */
    size?: 'compact' | 'default' | 'large';
    showUnit?: boolean;
    /** Anchor for countdown_seconds — pass measurement_point.last_value_at. */
    anchorAt?: string | number | null;
  }>(), {
    valueFormat: 'numeric',
    unit: null,
    enumValues: null,
    placeholder: '—',
    size: 'default',
    showUnit: true,
    anchorAt: null
  });

  const rootClasses = computed(() => {
    const classes: string[] = [`value-display--${props.size}`];
    return classes;
  });

  const booleanNumeric = computed(() => {
    if (typeof props.value === 'number')
      return props.value;

    return Number(props.value);
  });

  const booleanColor = computed(() => {
    return booleanNumeric.value ? 'success' : 'secondary';
  });

  const isCountdown = computed(() => props.valueFormat === 'countdown_seconds');
  const now = useNow();

  const anchorMs = computed(() => {
    if (props.anchorAt === null || props.anchorAt === undefined)
      return null;
    const ms = typeof props.anchorAt === 'number' ? props.anchorAt : Date.parse(props.anchorAt);
    return isNaN(ms) ? null : ms;
  });

  function isBitActive(bit: number) {
    return valueConverters.bitmask.isBitSet(props.value, bit);
  }

  const displayValue = computed(() => {
    return getDisplayValue(props.value, props.valueFormat, {
      unit: props.unit,
      enumValues: props.enumValues,
      showUnit: false,
      now: isCountdown.value ? now.value : undefined,
      anchorAt: isCountdown.value ? anchorMs.value : null
    });
  });

  const displayUnit = computed(() => {
    if (!props.showUnit || !props.unit)
      return null;

    // Don't show units for non-numeric formats
    if (props.valueFormat === 'time_of_day' ||
      props.valueFormat === 'ascii_string' ||
      props.valueFormat === 'countdown_seconds' ||
      props.valueFormat === 'bitmask')
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

  /* ── Bitmask badges ── */
  .value-display__bitmask {
    display: inline-flex;
    flex-wrap: wrap;
    gap: 0.25rem;
    align-items: center;
  }

  .value-display__bitmask-badge {
    font-size: 0.75rem;
    padding: 0.2em 0.5em;
    font-weight: 500;
  }

  .value-display--compact .value-display__bitmask-badge {
    font-size: 0.65rem;
    padding: 0.15em 0.4em;
  }

  .value-display--large .value-display__bitmask-badge {
    font-size: 0.85rem;
    padding: 0.25em 0.6em;
  }
</style>
