<template>
  <div v-if="weatherStationApiMetrics.length > 0" class="weather-overlay-toggle">
    <CFormLabel class="mb-1 small text-body-secondary">
      🌤️ Weather Overlay
    </CFormLabel>
    <div class="d-flex flex-wrap gap-3 align-items-center filter-input-height">
      <CFormCheck
        v-for="metric in weatherStationApiMetrics"
        class="mb-0 small"
        :key="metric.id"
        :id="`weather-metric-${metric.id}`"
        :label="metric.label"
        :checked="modelValue.includes(metric.id)"
        @change="toggleMetric(metric.id)" />
    </div>
  </div>
</template>

<script lang="ts" setup>
  import type { WeatherStationApiMetric } from '@/types/weather';

  const { weatherStationApiMetrics, modelValue } = defineProps<{
    weatherStationApiMetrics: WeatherStationApiMetric[];
    modelValue: WeatherStationApiMetric['id'][];
  }>();

  const emit = defineEmits<{
    (e: 'update:modelValue', value: WeatherStationApiMetric['id'][]): void;
  }>();

  function toggleMetric(metricId: WeatherStationApiMetric['id']) {
    const current = [...modelValue];
    const idx = current.indexOf(metricId);

    if (idx >= 0) current.splice(idx, 1);
    else current.push(metricId);

    emit('update:modelValue', current);
  }
</script>

<style scoped>
  .weather-overlay-toggle {
    min-width: 180px;
  }

  /* This matches the standard height of CoreUI 'sm' inputs
     to ensure the checkboxes are vertically centered with the selects */
  .filter-input-height {
    min-height: 31px; 
    display: flex;
    align-items: center;
  }

  /* Optional: make the checkbox labels a bit smaller to match the 'sm' theme */
  :deep(.form-check-label) {
    font-size: 0.875rem;
    line-height: 1;
  }
</style>
