<template>
  <div class="status-indicator">
    <CTooltip :content="statusTooltip">
      <template #toggler="{ id, on }">
        <div v-on="on" :class="['d-inline-block', 'status-dot', statusClass, sizeClass]">
        </div>
      </template>
    </CTooltip>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import type { MeasurementPoint } from '@/types/measurementPoint';

  const props = withDefaults(defineProps<{
    measurementPoint: MeasurementPoint;
    size?: 'sm' | 'md' | 'lg';
  }>(), {
    size: 'md'
  });

  const statusClass = computed(() => {
    if (!props.measurementPoint.active)
      return 'status-disabled';

    if (!props.measurementPoint.last_value_at)
      return 'status-unknown';

    const lastSeen = new Date(props.measurementPoint.last_value_at);

    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);
    if (lastSeen < tenMinutesAgo)
      return 'status-alarm';

    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
    if (lastSeen < fiveMinutesAgo)
      return 'status-warning';

    return 'status-normal';
  });

  const sizeClass = computed(() => {
    switch (props.size) {
      case 'sm':
        return 'status-dot-sm';
      case 'lg':
        return 'status-dot-lg';
      default:
        return 'status-dot-md';
    }
  });

  const statusTooltip = computed(() => {
    if (!props.measurementPoint.active)
      return 'Disabled';

    if (!props.measurementPoint.last_value_at)
      return 'No data received';

    const lastSeen = new Date(props.measurementPoint.last_value_at);

    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);
    if (lastSeen < tenMinutesAgo)
      return `Alarm - Last seen: ${lastSeen.toLocaleString()}`;

    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
    if (lastSeen < fiveMinutesAgo)
      return `Warning - Last seen: ${lastSeen.toLocaleString()}`;

    return `Online - Last updated: ${lastSeen.toLocaleString()}`;
  });
</script>

<style scoped>
  .status-indicator {
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .status-dot {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    position: relative;
  }

  .status-dot-sm {
    width: 8px;
    height: 8px;
  }

  .status-dot-md {
    width: 10px;
    height: 10px;
  }

  .status-dot-lg {
    width: 12px;
    height: 12px;
  }

  .status-normal {
    background-color: #10b981;
    box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.2);
  }

  .status-normal::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    border-radius: 50%;
    background-color: #10b981;
    animation: pulse 2s infinite;
  }

  .status-unknown {
    background-color: #9ca3af;
    box-shadow: 0 0 0 3px rgba(156, 163, 175, 0.2);
  }

  .status-disabled {
    background-color: #e5e7eb;
    box-shadow: 0 0 0 3px rgba(229, 231, 235, 0.2);
  }

  .status-alarm {
    background-color: #ef4444;
    box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.2);
    animation: blink 1s infinite;
  }

  .status-warning {
    background-color: #f59e0b;
    box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.2);
  }

  @keyframes pulse {
    0% {
      transform: scale(1);
      opacity: 1;
    }
    50% {
      transform: scale(1.5);
      opacity: 0;
    }
    100% {
      transform: scale(1);
      opacity: 0;
    }
  }

  @keyframes blink {
    0%, 50%, 100% {
      opacity: 1;
    }
    25%, 75% {
      opacity: 0.5;
    }
  }
</style>
