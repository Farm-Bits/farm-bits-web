<template>
  <div v-if="weatherStationApiMetrics.length > 0" class="weather-overlay-toggle">
    <CFormLabel class="mb-1 small text-body-secondary d-flex align-items-center gap-1">
      <span>🌤️</span>
      <span>Weather Overlay</span>
    </CFormLabel>
    <div class="d-flex flex-wrap gap-2">
      <CFormCheck
        v-for="metric in weatherStationApiMetrics"
        :key="metric.id"
        :id="`weather-metric-${metric.id}`"
        type="checkbox"
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

    if (idx >= 0)
      current.splice(idx, 1);
    else
      current.push(metricId);

    emit('update:modelValue', current);
  }
</script>

<style scoped>
  .weather-overlay-toggle {
    min-width: 180px;
  }
</style>
