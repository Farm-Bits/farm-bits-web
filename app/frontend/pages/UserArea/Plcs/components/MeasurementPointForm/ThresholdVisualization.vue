<template>
  <div class="threshold-visualization">
    <div class="threshold-bar">
      <!-- Alarm Low Zone -->
      <div
        v-if="hasAlarmLow"
        class="zone zone-alarm-low"
        :style="{ width: alarmLowWidth }">
        <span class="zone-label">Alarm</span>
      </div>

      <!-- Warning Low Zone -->
      <div
        v-if="hasWarningLow"
        class="zone zone-warning-low"
        :style="{ width: warningLowWidth }">
        <span class="zone-label">Warning</span>
      </div>

      <!-- Normal Zone -->
      <div
        class="zone zone-normal"
        :style="{ width: normalWidth }">
        <span class="zone-label">Normal</span>
      </div>

      <!-- Warning High Zone -->
      <div
        v-if="hasWarningHigh"
        class="zone zone-warning-high"
        :style="{ width: warningHighWidth }">
        <span class="zone-label">Warning</span>
      </div>

      <!-- Alarm High Zone -->
      <div
        v-if="hasAlarmHigh"
        class="zone zone-alarm-high"
        :style="{ width: alarmHighWidth }">
        <span class="zone-label">Alarm</span>
      </div>
    </div>

    <!-- Value markers -->
    <div class="threshold-markers">
      <div v-if="hasAlarmLow" class="marker" :style="{ left: alarmLowPosition }">
        <div class="marker-line marker-alarm"></div>
        <div class="marker-value">{{ formatValue(alarmLow) }}</div>
      </div>
      <div v-if="hasWarningLow" class="marker" :style="{ left: warningLowPosition }">
        <div class="marker-line marker-warning"></div>
        <div class="marker-value">{{ formatValue(warningLow) }}</div>
      </div>
      <div v-if="hasWarningHigh" class="marker" :style="{ left: warningHighPosition }">
        <div class="marker-line marker-warning"></div>
        <div class="marker-value">{{ formatValue(warningHigh) }}</div>
      </div>
      <div v-if="hasAlarmHigh" class="marker" :style="{ left: alarmHighPosition }">
        <div class="marker-line marker-alarm"></div>
        <div class="marker-value">{{ formatValue(alarmHigh) }}</div>
      </div>
    </div>

    <!-- Legend -->
    <div class="threshold-legend mt-3">
      <div class="legend-item">
        <span class="legend-color legend-normal"></span>
        <span class="legend-text">Normal Range</span>
      </div>
      <div class="legend-item">
        <span class="legend-color legend-warning"></span>
        <span class="legend-text">Warning Zone</span>
      </div>
      <div class="legend-item">
        <span class="legend-color legend-alarm"></span>
        <span class="legend-text">Alarm Zone</span>
      </div>
    </div>

    <!-- No thresholds message -->
    <div v-if="!hasAnyThreshold" class="text-center text-muted py-3">
      <CIcon icon="cilInfo" class="me-2" />
      No thresholds configured. Set values above to see the visualization.
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';

  const props = defineProps<{
    alarmLow: number | null;
    warningLow: number | null;
    warningHigh: number | null;
    alarmHigh: number | null;
    unit: string;
  }>();

  const hasAlarmLow = computed(() => props.alarmLow !== null && props.alarmLow !== undefined);
  const hasWarningLow = computed(() => props.warningLow !== null && props.warningLow !== undefined);
  const hasWarningHigh = computed(() => props.warningHigh !== null && props.warningHigh !== undefined);
  const hasAlarmHigh = computed(() => props.alarmHigh !== null && props.alarmHigh !== undefined);

  const hasAnyThreshold = computed(() =>
    hasAlarmLow.value || hasWarningLow.value || hasWarningHigh.value || hasAlarmHigh.value
  );

  const visualRange = computed(() => {
    const values = [
      props.alarmLow,
      props.warningLow,
      props.warningHigh,
      props.alarmHigh
    ].filter((v): v is number => v !== null && v !== undefined);

    if (values.length === 0) {
      return { min: 0, max: 100 };
    }

    const min = Math.min(...values);
    const max = Math.max(...values);
    const range = max - min || 1;
    const padding = range * 0.2;

    return {
      min: min - padding,
      max: max + padding
    };
  });

  function valueToPercent(value: number | null) {
    if (value === null)
      return 0;

    const { min, max } = visualRange.value;
    return ((value - min) / (max - min)) * 100;
  }

  const alarmLowWidth = computed(() => {
    if (!hasAlarmLow.value)
      return '0%';

    return `${valueToPercent(props.alarmLow)}%`;
  });

  const warningLowWidth = computed(() => {
    if (!hasWarningLow.value)
      return '0%';

    const start = hasAlarmLow.value ? valueToPercent(props.alarmLow) : 0;
    const end = valueToPercent(props.warningLow);
    return `${end - start}%`;
  });

  const normalWidth = computed(() => {
    const start = hasWarningLow.value ? valueToPercent(props.warningLow) :
                  hasAlarmLow.value ? valueToPercent(props.alarmLow) : 0;
    const end = hasWarningHigh.value ? valueToPercent(props.warningHigh) :
                hasAlarmHigh.value ? valueToPercent(props.alarmHigh) : 100;
    return `${end - start}%`;
  });

  const warningHighWidth = computed(() => {
    if (!hasWarningHigh.value)
      return '0%';

    const start = valueToPercent(props.warningHigh);
    const end = hasAlarmHigh.value ? valueToPercent(props.alarmHigh) : 100;
    return `${end - start}%`;
  });

  const alarmHighWidth = computed(() => {
    if (!hasAlarmHigh.value)
      return '0%';

    return `${100 - valueToPercent(props.alarmHigh)}%`;
  });

  const alarmLowPosition = computed(() => `${valueToPercent(props.alarmLow)}%`);
  const warningLowPosition = computed(() => `${valueToPercent(props.warningLow)}%`);
  const warningHighPosition = computed(() => `${valueToPercent(props.warningHigh)}%`);
  const alarmHighPosition = computed(() => `${valueToPercent(props.alarmHigh)}%`);

  function formatValue(value: number | null) {
    if (value === null)
      return '';

    const formatted = Number.isInteger(value) ? value.toString() : value.toFixed(2);
    return props.unit ? `${formatted} ${props.unit}` : formatted;
  }
</script>

<style scoped>
  .threshold-visualization {
    position: relative;
  }

  .threshold-bar {
    display: flex;
    height: 32px;
    border-radius: 4px;
    overflow: hidden;
    background: #e9ecef;
  }

  .zone {
    display: flex;
    align-items: center;
    justify-content: center;
    min-width: 0;
    transition: width 0.3s ease;
  }

  .zone-label {
    font-size: 0.7rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.025em;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    padding: 0 4px;
  }

  .zone-alarm-low,
  .zone-alarm-high {
    background: rgba(220, 53, 69, 0.2);
    color: #dc3545;
  }

  .zone-warning-low,
  .zone-warning-high {
    background: rgba(255, 193, 7, 0.2);
    color: #856404;
  }

  .zone-normal {
    background: rgba(40, 167, 69, 0.2);
    color: #28a745;
  }

  .threshold-markers {
    position: relative;
    height: 40px;
    margin-top: 4px;
  }

  .marker {
    position: absolute;
    transform: translateX(-50%);
    text-align: center;
  }

  .marker-line {
    width: 2px;
    height: 12px;
    margin: 0 auto;
  }

  .marker-alarm {
    background: #dc3545;
  }

  .marker-warning {
    background: #ffc107;
  }

  .marker-value {
    font-size: 0.75rem;
    color: #6c757d;
    white-space: nowrap;
    margin-top: 2px;
  }

  .threshold-legend {
    display: flex;
    justify-content: center;
    gap: 1.5rem;
    flex-wrap: wrap;
  }

  .legend-item {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .legend-color {
    width: 16px;
    height: 16px;
    border-radius: 3px;
  }

  .legend-normal {
    background: rgba(40, 167, 69, 0.3);
    border: 1px solid #28a745;
  }

  .legend-warning {
    background: rgba(255, 193, 7, 0.3);
    border: 1px solid #ffc107;
  }

  .legend-alarm {
    background: rgba(220, 53, 69, 0.3);
    border: 1px solid #dc3545;
  }

  .legend-text {
    font-size: 0.8rem;
    color: #6c757d;
  }
</style>
