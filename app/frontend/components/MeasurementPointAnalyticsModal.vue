<template>
  <CModal
    :visible="visible"
    size="xl"
    scrollable
    @close="emit('close')">
    <CModalHeader>
      <h5 class="modal-title">{{ modalTitle }}</h5>
    </CModalHeader>

    <CModalBody>
      <!-- Date range + aggregation filter -->
      <div class="d-flex align-items-end gap-3 mb-4">
        <DateRangeFilter v-model="dateRange" />
        <div v-if="isSingleDay">
          <CFormLabel class="mb-1 small text-body-secondary">Aggregation</CFormLabel>
          <CFormSelect
            v-model="aggregationLevel"
            size="sm"
            style="max-width: 120px;">
            <option value="hourly">Hourly</option>
            <option value="raw">Raw</option>
          </CFormSelect>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="analytics.loading.value" class="text-center py-5">
        <CSpinner color="primary" />
        <p class="mt-2 text-body-secondary">Loading analytics data...</p>
      </div>

      <!-- Error -->
      <CAlert v-else-if="analytics.error.value" color="danger" class="mb-3">
        {{ analytics.error.value }}
      </CAlert>

      <!-- No data -->
      <div v-else-if="!hasAnyData" class="text-center py-5 text-body-secondary">
        <CIcon name="cil-chart-line" size="xl" class="mb-2" />
        <p class="mb-0">No data available for the selected period</p>
      </div>

      <!-- Chart + Summary -->
      <template v-else>
        <CCard class="mb-4 shadow-sm">
          <CCardBody>
            <ComboTimeSeriesChart :entries="chartEntries" />
          </CCardBody>
        </CCard>

        <CCard class="shadow-sm">
          <CCardHeader>
            <h6 class="mb-0">Summary</h6>
          </CCardHeader>
          <CCardBody>
            <SummaryTable :rows="summaryData" />
          </CCardBody>
        </CCard>
      </template>
    </CModalBody>
  </CModal>
</template>

<script lang="ts" setup>
  import { ref, computed, watch } from 'vue';
  import { useAnalyticsData } from '@/composables/useAnalyticsData';
  import DateRangeFilter, { type DateRange } from '@/components/DateRangeFilter.vue';
  import ComboTimeSeriesChart, { type ChartEntry } from '@/components/ComboTimeSeriesChart.vue';
  import SummaryTable, { type RowDefinition } from '@/components/SummaryTable.vue';
  import { mapMeasurementPointToSerieDefinition } from '@/utils/valueFormaters';
  import type { LiveMeasurementPoint, AggregationLevel } from '@/types/analytics';

  const { visible, measurementPoints } = defineProps<{
    visible: boolean;
    measurementPoints: LiveMeasurementPoint[];
  }>();

  const emit = defineEmits<{
    (e: 'close'): void;
  }>();

  // ── Filters ──

  const today = new Date().toISOString().slice(0, 10);
  const dateRange = ref<DateRange>({ start: today, end: today });
  const aggregationLevel = ref<AggregationLevel>('hourly');

  const isSingleDay = computed(() => dateRange.value.start === dateRange.value.end);

  const summaryData = computed<RowDefinition[]>(() => {
    return measurementPoints.map((mp) => {
      const serieDefinition = mapMeasurementPointToSerieDefinition(mp);
      const summary = analytics.summary.value[serieDefinition.id];
      return {
        ...serieDefinition,
        summary
      };
    });
  });

  // ── Analytics data (own instance, independent from the Analytics page) ──

  const analytics = useAnalyticsData();

  // ── Modal title ──

  const modalTitle = computed(() => {
    if (measurementPoints.length === 1)
      return measurementPoints[0].name;

    return `Analytics — ${measurementPoints.length} measurement points`;
  });

  // ── Chart entries ──

  const chartEntries = computed<ChartEntry[]>(() =>
    measurementPoints.map((mp) => ({
      serieDefinition: mapMeasurementPointToSerieDefinition(mp),
      hourlyData: aggregationLevel.value === 'hourly'
        ? (analytics.aggregations.value[mp.id] ?? [])
        : [],
      rawData: aggregationLevel.value === 'raw'
        ? (analytics.rawValues.value[mp.id] ?? [])
        : [],
    }))
  );

  const hasAnyData = computed(() =>
    chartEntries.value.some((e) => e.hourlyData.length > 0 || e.rawData.length > 0)
  );

  // ── Data fetching ──

  async function loadData() {
    const mpIds = measurementPoints.map((mp) => mp.id);
    if (mpIds.length === 0) {
      analytics.clear();
      return;
    }

    if (aggregationLevel.value === 'raw' && isSingleDay.value) {
      const startTime = `${dateRange.value.start}T00:00:00`;
      const endTime = `${dateRange.value.end}T23:59:59`;
      await analytics.fetchRaw(mpIds, startTime, endTime);
    } else
      await analytics.fetchHourly(mpIds, dateRange.value);
  }

  // Auto-correct aggregation when switching away from single day
  watch(isSingleDay, (single) => {
    if (!single && aggregationLevel.value === 'raw')
      aggregationLevel.value = 'hourly';
  });

  // Reload when filters change (only when modal is visible)
  watch(
    [() => visible, dateRange, aggregationLevel],
    ([isVisible]) => {
      if (isVisible)
        loadData();
    },
  );

  // Reload when measurement points change (new modal opened with different MPs)
  watch(
    () => measurementPoints,
    () => {
      if (visible)
        loadData();
    },
  );

  // Initial load when modal first opens
  watch(
    () => visible,
    (isVisible) => {
      if (isVisible)
        loadData();
    },
    { immediate: true }
  );
</script>
