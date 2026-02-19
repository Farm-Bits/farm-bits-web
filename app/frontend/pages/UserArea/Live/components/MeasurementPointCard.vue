<template>
  <div
    class="mp-card"
    :class="{ 'mp-card--alarm': isAlarm, 'mp-card--warning': isWarning }"
    role="button"
    @click="emit('click', measurementPoint)"
  >
    <div class="d-flex align-items-start justify-content-between">
      <div class="d-flex align-items-center gap-2 mb-1">
        <span
          class="status-dot"
          :class="statusDotClass"
          :title="statusTooltip"
        />
        <span class="mp-card__name">{{ measurementPoint.name }}</span>
      </div>
      <CBadge v-if="alarmBadge" :color="alarmBadge.color" size="sm">
        {{ alarmBadge.label }}
      </CBadge>
    </div>

    <div class="mp-card__value">
      <template v-if="measurementPoint.last_value !== null">
        <span class="mp-card__number">{{ formattedValue }}</span>
        <span v-if="measurementPoint.effective_unit" class="mp-card__unit">
          {{ measurementPoint.effective_unit }}
        </span>
      </template>
      <span v-else class="text-body-secondary">No data</span>
    </div>

    <div class="mp-card__meta d-flex align-items-center gap-2">
      <span class="small text-body-secondary">{{ measurementPoint.plc_name }}</span>
      <span class="small text-body-secondary">·</span>
      <span class="small text-body-secondary">{{ measurementPoint.register_name }}</span>
      <span v-if="measurementPoint.last_value_at" class="small text-body-secondary ms-auto">
        <RelativeTime :datetime="measurementPoint.last_value_at" />
      </span>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import RelativeTime from '@/components/RelativeTime.vue';
  import { type LiveMeasurementPoint } from '@/types/analytics';

  const { measurementPoint } = defineProps<{
    measurementPoint: LiveMeasurementPoint;
  }>();

  const emit = defineEmits<{
    (e: 'click', mp: LiveMeasurementPoint): void;
  }>();

  const isAlarm = computed(() => {
    return measurementPoint.alarm_state === 'alarm_low' || measurementPoint.alarm_state === 'alarm_high';
  });

  const isWarning = computed(() => {
    return measurementPoint.alarm_state === 'warning_low' || measurementPoint.alarm_state === 'warning_high';
  });

  const formattedValue = computed(() => {
    const val = measurementPoint.last_value;
    if (val === null)
      return '';

    if (typeof val === 'number')
      return Number(val.toFixed(2)).toLocaleString();

    return String(val);
  });

  const statusDotClass = computed(() => {
    if (!measurementPoint.last_value_at)
      return 'status-dot--unknown';

    const lastAt = new Date(measurementPoint.last_value_at);
    const diffMs = Date.now() - lastAt.getTime();
    const fiveMinutes = 5 * 60 * 1000;

    if (isAlarm.value)
      return 'status-dot--alarm';

    if (isWarning.value)
      return 'status-dot--warning';

    if (diffMs > fiveMinutes)
      return 'status-dot--stale';

    return 'status-dot--online';
  });

  const statusTooltip = computed(() => {
    const state = measurementPoint.alarm_state;
    if (!state || state === 'normal')
      return 'Normal';

    return state.replace('_', ' ').replace(/\b\w/g, (c) => c.toUpperCase());
  });

  const alarmBadge = computed<{ color: string; label: string } | null>(() => {
    const state = measurementPoint.alarm_state;
    if (!state || state === 'normal')
      return null;

    const badges: Record<string, { color: string; label: string }> = {
      alarm_low: { color: 'danger', label: 'Alarm Low' },
      alarm_high: { color: 'danger', label: 'Alarm High' },
      warning_low: { color: 'warning', label: 'Warning Low' },
      warning_high: { color: 'warning', label: 'Warning High' },
    };

    return badges[state] ?? null;
  });
</script>

<style scoped>
  .mp-card {
    padding: 0.75rem;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    cursor: pointer;
    transition: box-shadow 0.15s, border-color 0.15s;
    background: #fff;
  }

  .mp-card:hover {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
    border-color: var(--primary-color);
  }

  .mp-card--alarm {
    border-color: #ef4444;
    background: #fef2f2;
  }

  .mp-card--warning {
    border-color: #f59e0b;
    background: #fffbeb;
  }

  .mp-card__name {
    font-weight: 600;
    font-size: 0.875rem;
    color: #374151;
  }

  .mp-card__value {
    margin: 0.25rem 0;
  }

  .mp-card__number {
    font-size: 1.5rem;
    font-weight: 700;
    color: #111827;
    line-height: 1.2;
  }

  .mp-card__unit {
    font-size: 0.875rem;
    color: #6b7280;
    margin-left: 0.25rem;
  }

  .status-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .status-dot--online {
    background-color: #10b981;
    animation: pulse 2s ease-in-out infinite;
  }

  .status-dot--stale {
    background-color: #f59e0b;
  }

  .status-dot--unknown {
    background-color: #9ca3af;
  }

  .status-dot--alarm {
    background-color: #ef4444;
    animation: blink 1s ease-in-out infinite;
  }

  .status-dot--warning {
    background-color: #f59e0b;
  }

  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
  }

  @keyframes blink {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.3; }
  }
</style>
