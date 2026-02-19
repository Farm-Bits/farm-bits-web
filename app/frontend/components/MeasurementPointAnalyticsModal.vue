<template>
  <CModal
    :visible="visible"
    size="xl"
    @close="emit('close')">
    <CModalHeader>
      <h5 class="modal-title">{{ modalTitle }}</h5>
    </CModalHeader>
    <CModalBody>
      <div class="d-flex align-items-center gap-3 mb-3">
        <DateRangeFilter v-model="dateRange" />
        <div v-if="isSingleDay" class="d-flex align-items-center gap-2">
          <CFormLabel class="mb-0 small text-body-secondary">Level</CFormLabel>
          <CFormSelect
            v-model="aggregationLevel"
            size="sm"
            style="max-width: 120px;">
            <option value="hourly">Hourly</option>
            <option value="raw">Raw</option>
          </CFormSelect>
        </div>
      </div>

      <div v-if="loading" class="text-center py-5">
        <CSpinner color="primary" />
        <p class="mt-2 text-body-secondary">Loading data...</p>
      </div>

      <div v-else-if="error" class="py-4">
        <CAlert color="danger">{{ error }}</CAlert>
      </div>

      <template v-else>
        <div v-for="group in chartGroups" :key="group.valueType" class="mb-4">
          <h6 v-if="chartGroups.length > 1" class="text-body-secondary mb-2">
            {{ valueTypeLabel(group.valueType) }}
          </h6>

          <template v-if="group.valueType === 'status'">
            <div v-for="mp in group.measurementPoints" :key="mp.id" class="mb-3">
              <p class="small fw-medium mb-1">{{ mp.name }}</p>
              <StatusTimeline
                :hourly-data="aggregationLevel === 'hourly' ? (aggregations[mp.id] ?? []) : []"
                :raw-data="aggregationLevel === 'raw' ? (rawValues[mp.id] ?? []) : []" />
            </div>
          </template>
          <template v-else>
            <div v-for="mp in group.measurementPoints" :key="mp.id" class="mb-3">
              <TimeSeriesChart
                :hourly-data="aggregationLevel === 'hourly' ? (aggregations[mp.id] ?? []) : []"
                :raw-data="aggregationLevel === 'raw' ? (rawValues[mp.id] ?? []) : []"
                :value-type="group.valueType"
                :chart-type="mp.effective_chart_type ?? 'line'"
                :color="mp.effective_color ?? '#059669'"
                :unit="mp.effective_unit ?? ''"
                :title="mp.name"
                :thresholds="{
                  alarm_low: mp.alarm_low,
                  alarm_high: mp.alarm_high,
                  warning_low: mp.warning_low,
                  warning_high: mp.warning_high,
                }" />
            </div>
          </template>

          <CCard class="shadow-sm">
            <CCardBody>
              <SummaryTable
                :measurement-points="group.measurementPoints"
                :summary-data="summary"
                :value-type="group.valueType" />
            </CCardBody>
          </CCard>
        </div>
      </template>
    </CModalBody>
  </CModal>
</template>

<script lang="ts" setup>
  import { ref, computed, watch } from 'vue';
  import DateRangeFilter, { type DateRange } from './DateRangeFilter.vue';
  import TimeSeriesChart from './TimeSeriesChart.vue';
  import StatusTimeline from './StatusTimeline.vue';
  import SummaryTable from './SummaryTable.vue';
  import { useAnalyticsData } from '@/composables/useAnalyticsData';
  import type { AggregationLevel, LiveMeasurementPoint } from '@/types/analytics';
  import type { ValueType } from '@/types/measurementPoint';

  const {
    visible,
    measurementPoints,
    initialDateRange,
  } = defineProps<{
    visible: boolean;
    measurementPoints: LiveMeasurementPoint[];
    initialDateRange?: DateRange;
  }>();

  const emit = defineEmits<{
    (e: 'close'): void;
  }>();

  const today = new Date().toISOString().slice(0, 10);
  const dateRange = ref<DateRange>(initialDateRange ?? { start: today, end: today });
  const aggregationLevel = ref<AggregationLevel>('hourly');

  const {
    aggregations,
    rawValues,
    summary,
    loading,
    error,
    fetchHourly,
    fetchRaw,
    clear
  } = useAnalyticsData();

  const isSingleDay = computed(() => dateRange.value.start === dateRange.value.end);

  const modalTitle = computed(() => {
    if (measurementPoints.length === 1)
      return measurementPoints[0].name;

    return `Analytics — ${measurementPoints.length} measurement points`;
  });

  const chartGroups = computed<{
    valueType: ValueType;
    measurementPoints: LiveMeasurementPoint[];
  }[]>(() => {
    const grouped = new Map<ValueType, LiveMeasurementPoint[]>();
    for (const mp of measurementPoints) {
      if (!mp.measurement_subtype)
        continue;

      const vt = mp.measurement_subtype.value_type;
      if (!grouped.has(vt))
        grouped.set(vt, []);

      grouped.get(vt)!.push(mp);
    }
    return Array.from(grouped.entries()).map(([valueType, mps]) => ({
      valueType,
      measurementPoints: mps,
    }));
  });

  function valueTypeLabel(vt: ValueType) {
    const labels: Record<ValueType, string> = {
      instantaneous: 'Instantaneous',
      accumulative: 'Accumulative',
      status: 'Status',
    };
    return labels[vt] ?? vt;
  }

  async function loadData() {
    const mpIds = measurementPoints.map((mp) => mp.id);
    if (mpIds.length === 0)
      return;

    clear();

    if (aggregationLevel.value === 'raw' && isSingleDay.value) {
      const startTime = `${dateRange.value.start}T00:00:00`;
      const endTime = `${dateRange.value.end}T23:59:59`;
      await fetchRaw(mpIds, startTime, endTime);
    } else
      await fetchHourly(mpIds, dateRange.value);
  }

  // Reload when filters change
  watch([dateRange, aggregationLevel], () => {
    if (!isSingleDay.value && aggregationLevel.value === 'raw') {
      aggregationLevel.value = 'hourly';
      return;
    }
    loadData();
  });

  // Load on open
  watch(
    () => visible,
    (val) => {
      if (val)
        loadData();
    },
    { immediate: true }
  );
</script>
