<template>
  <CContainer fluid class="px-4 py-4">
    <!-- Header -->
    <div class="mb-4">
      <h2 class="mb-1">Analytics</h2>
      <p class="text-body-secondary mb-0">
        Historical data visualization and summaries for {{ currentSite?.name }}
      </p>
    </div>

    <!-- Filter bar -->
    <CCard class="mb-4 shadow-sm">
      <CCardBody class="py-3">
        <div class="row g-3 align-items-end">
          <div class="col-auto">
            <SegmentFilter
              v-model="selectedSegmentId"
              :segments="segments" />
          </div>
          <div class="col-auto">
            <DateRangeFilter v-model="dateRange" />
          </div>
          <div v-if="isSingleDay" class="col-auto">
            <CFormLabel class="mb-1 small text-body-secondary">Aggregation</CFormLabel>
            <CFormSelect
              v-model="aggregationLevel"
              size="sm"
              style="max-width: 120px;">
              <option value="hourly">Hourly</option>
              <option value="raw">Raw</option>
            </CFormSelect>
          </div>
          <div class="col-auto">
            <GroupByToggle v-model="groupBy" />
          </div>
        </div>
      </CCardBody>
    </CCard>

    <!-- Loading -->
    <div v-if="analytics.loading.value" class="text-center py-5">
      <CSpinner color="primary" />
      <p class="mt-2 text-body-secondary">Loading analytics data...</p>
    </div>

    <!-- Error -->
    <CAlert v-else-if="analytics.error.value" color="danger" class="mb-4">
      {{ analytics.error.value }}
    </CAlert>

    <!-- Empty state -->
    <div v-else-if="filteredMeasurementPoints.length === 0" class="text-center py-5">
      <CIcon name="cil-chart-line" size="3xl" class="text-body-secondary mb-3" />
      <h5 class="text-body-secondary">No active measurement points</h5>
      <p class="text-body-secondary">
        There are no active measurement points with data collection enabled for this site.
      </p>
    </div>

    <!-- Analytics content by group -->
    <template v-else>
      <div v-for="group in groups" :key="group.key" class="mb-5">
        <h5 class="mb-3">
          {{ group.label }}
          <CBadge color="light" class="ms-2 text-body-secondary">
            {{ group.measurementPoints.length }}
          </CBadge>
        </h5>

        <!-- Charts per value type within group -->
        <div v-for="vtGroup in valueTypeGroups(group.measurementPoints)" :key="vtGroup.valueType">
          <CCard class="mb-4 shadow-sm">
            <CCardHeader v-if="hasMultipleValueTypes(group.measurementPoints)">
              <h6 class="mb-0">{{ valueTypeLabel(vtGroup.valueType) }}</h6>
            </CCardHeader>
            <CCardBody>
              <!-- Status: one timeline per MP -->
              <template v-if="vtGroup.valueType === 'status'">
                <div v-for="mp in vtGroup.measurementPoints" :key="mp.id" class="mb-3">
                  <p class="small fw-medium mb-1">{{ mp.name }}</p>
                  <StatusTimeline
                    :hourly-data="aggregationLevel === 'hourly' ? (analytics.aggregations.value[mp.id] ?? []) : []"
                    :raw-data="aggregationLevel === 'raw' ? (analytics.rawValues.value[mp.id] ?? []) : []" />
                </div>
              </template>

              <!-- Instantaneous / Accumulative: chart per MP -->
              <template v-else>
                <div v-for="mp in vtGroup.measurementPoints" :key="mp.id" class="mb-3">
                  <TimeSeriesChart
                    v-if="mp.effective_chart_type !== 'state'"
                    :hourly-data="aggregationLevel === 'hourly' ? (analytics.aggregations.value[mp.id] ?? []) : []"
                    :raw-data="aggregationLevel === 'raw' ? (analytics.rawValues.value[mp.id] ?? []) : []"
                    :value-type="vtGroup.valueType"
                    :chart-type="mp.effective_chart_type"
                    :color="mp.effective_color ?? '#059669'"
                    :unit="mp.effective_unit ?? ''"
                    :title="mp.name"
                    :thresholds="{
                      alarm_low: mp.alarm_low,
                      alarm_high: mp.alarm_high,
                      warning_low: mp.warning_low,
                      warning_high: mp.warning_high,
                    }" />
                  <StatusTimeline
                    v-else
                    :hourly-data="aggregationLevel === 'hourly' ? (analytics.aggregations.value[mp.id] ?? []) : []"
                    :raw-data="aggregationLevel === 'raw' ? (analytics.rawValues.value[mp.id] ?? []) : []" />
                </div>
              </template>
            </CCardBody>
          </CCard>

          <!-- Summary table -->
          <CCard class="mb-4 shadow-sm">
            <CCardHeader>
              <h6 class="mb-0">Summary</h6>
            </CCardHeader>
            <CCardBody>
              <SummaryTable
                :measurement-points="vtGroup.measurementPoints"
                :summary-data="analytics.summary.value"
                :value-type="vtGroup.valueType" />
            </CCardBody>
          </CCard>
        </div>
      </div>

      <!-- Hour drill-down modal -->
      <CModal
        :visible="drillDownVisible"
        size="lg"
        @close="drillDownVisible = false">
        <CModalHeader>
          <h5 class="modal-title">
            Raw data — {{ drillDownLabel }}
          </h5>
        </CModalHeader>
        <CModalBody>
          <div v-if="drillDownLoading" class="text-center py-4">
            <CSpinner color="primary" size="sm" />
          </div>
          <template v-else>
            <TimeSeriesChart
              v-if="drillDownMp && drillDownMp.measurement_subtype?.value_type !== 'status'"
              :raw-data="drillDownRawValues"
              :value-type="drillDownMp.measurement_subtype?.value_type ?? 'instantaneous'"
              :color="drillDownMp.effective_color ?? '#059669'"
              :unit="drillDownMp.effective_unit ?? ''"
              :title="drillDownMp.name"
              :height="250" />
            <StatusTimeline
              v-else-if="drillDownMp"
              :raw-data="drillDownRawValues" />
          </template>
        </CModalBody>
      </CModal>
    </template>
  </CContainer>
</template>

<script lang="ts" setup>
  import { ref, computed, watch } from 'vue';
  import useAuth from '@/composables/useAuth';
  import { useAnalyticsData } from '@/composables/useAnalyticsData';
  import SegmentFilter from '@/components/SegmentFilter.vue';
  import DateRangeFilter, { type DateRange } from '@/components/DateRangeFilter.vue';
  import GroupByToggle, { type GroupBy } from '@/components/GroupByToggle.vue';
  import TimeSeriesChart from '@/components/TimeSeriesChart.vue';
  import StatusTimeline from '@/components/StatusTimeline.vue';
  import SummaryTable from '@/components/SummaryTable.vue';
  import type { Segment } from '@/types/location';
  import type { MeasurementSubtype, ValueType } from '@/types/measurementPoint';
  import type {
    LiveMeasurementPoint,
    MeasurementPointGroup,
    AggregationLevel,
    RawValue,
  } from '@/types/analytics';

  const { currentSite, pageProps } = useAuth<{
    segments: Segment[];
    measurement_points: LiveMeasurementPoint[];
    measurement_subtypes: MeasurementSubtype[];
  }>();
  const { segments } = pageProps.value;
  const allMeasurementPoints = pageProps.value.measurement_points;

  // Filters
  const selectedSegmentId = ref<number | null>(null);
  const today = new Date().toISOString().slice(0, 10);
  const dateRange = ref<DateRange>({ start: today, end: today });
  const aggregationLevel = ref<AggregationLevel>('hourly');
  const groupBy = ref<GroupBy>('segment');

  const isSingleDay = computed(() => dateRange.value.start === dateRange.value.end);

  // Analytics data
  const analytics = useAnalyticsData();

  // Drill-down state
  const drillDownVisible = ref(false);
  const drillDownLoading = ref(false);
  const drillDownMp = ref<LiveMeasurementPoint | null>(null);
  const drillDownLabel = ref('');
  const drillDownRawValues = ref<RawValue[]>([]);

  // Filtered measurement points
  const filteredMeasurementPoints = computed<LiveMeasurementPoint[]>(() => {
    if (selectedSegmentId.value === null)
      return allMeasurementPoints;

    return allMeasurementPoints.filter(
      (mp) => mp.segment_id === selectedSegmentId.value
    );
  });

  // Grouped
  const groups = computed<MeasurementPointGroup[]>(() => {
    const mps = filteredMeasurementPoints.value;

    if (groupBy.value === 'segment')
      return groupBySegmentFn(mps);

    return groupByMeasurementTypeFn(mps);
  });

  function groupBySegmentFn(mps: LiveMeasurementPoint[]): MeasurementPointGroup[] {
    const map = new Map<string, LiveMeasurementPoint[]>();
    for (const mp of mps) {
      const key = mp.segment_id ? String(mp.segment_id) : 'unassigned';
      if (!map.has(key))
        map.set(key, []);
      map.get(key)!.push(mp);
    }
    return Array.from(map.entries()).map(([key, groupMps]) => {
      const segment = segments.find((s) => String(s.id) === key);
      return { key, label: segment?.name ?? 'Unassigned', measurementPoints: groupMps };
    });
  }

  function groupByMeasurementTypeFn(mps: LiveMeasurementPoint[]): MeasurementPointGroup[] {
    const map = new Map<string, LiveMeasurementPoint[]>();
    for (const mp of mps) {
      const typeName = mp.measurement_subtype?.measurement_type?.name ?? 'Unknown';
      if (!map.has(typeName))
        map.set(typeName, []);
      map.get(typeName)!.push(mp);
    }
    return Array.from(map.entries())
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([key, groupMps]) => ({ key, label: key, measurementPoints: groupMps }));
  }

  function valueTypeGroups(mps: LiveMeasurementPoint[]) {
    const map = new Map<ValueType, LiveMeasurementPoint[]>();
    for (const mp of mps) {
      const vt = mp.measurement_subtype?.value_type ?? 'instantaneous';
      if (!map.has(vt))
        map.set(vt, []);
      map.get(vt)!.push(mp);
    }
    return Array.from(map.entries()).map(([valueType, groupMps]) => ({
      valueType,
      measurementPoints: groupMps,
    }));
  }

  function hasMultipleValueTypes(mps: LiveMeasurementPoint[]) {
    const types = new Set(mps.map((mp) => mp.measurement_subtype?.value_type));
    return types.size > 1;
  }

  function valueTypeLabel(vt: ValueType) {
    const labels: Record<ValueType, string> = {
      instantaneous: 'Instantaneous',
      accumulative: 'Accumulative',
      status: 'Status',
    };
    return labels[vt] ?? vt;
  }

  // Data fetching
  async function loadData() {
    const mpIds = filteredMeasurementPoints.value.map((mp) => mp.id);
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

  // Auto-correct aggregation level
  watch(isSingleDay, (single) => {
    if (!single && aggregationLevel.value === 'raw') {
      aggregationLevel.value = 'hourly';
    }
  });

  // Reload on filter changes
  watch(
    [dateRange, aggregationLevel, selectedSegmentId],
    () => { loadData(); },
    { immediate: true }
  );
</script>
