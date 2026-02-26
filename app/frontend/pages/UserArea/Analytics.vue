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

        <!-- Single combo chart for all measurement points in the group, with weather overlay -->
        <CCard class="mb-4 shadow-sm">
          <CCardBody>
            <ComboTimeSeriesChart :entries="chartEntries(group.measurementPoints)" />
          </CCardBody>
        </CCard>

        <!-- Summary table for all measurement points in the group -->
        <CCard class="mb-4 shadow-sm">
          <CCardHeader>
            <h6 class="mb-0">Summary</h6>
          </CCardHeader>
          <CCardBody>
            <SummaryTable
              :measurement-points="group.measurementPoints"
              :summary-data="analytics.summary.value" />
          </CCardBody>
        </CCard>
      </div>
    </template>
  </CContainer>
</template>

<script lang="ts" setup>
  import { computed, ref, watch } from 'vue';
  import useAuth from '@/composables/useAuth';
  import { useAnalyticsData } from '@/composables/useAnalyticsData';
  import { useWeatherAnalyticsData } from '@/composables/useWeatherAnalyticsData';
  import SegmentFilter from '@/components/SegmentFilter.vue';
  import DateRangeFilter, { type DateRange } from '@/components/DateRangeFilter.vue';
  import GroupByToggle, { type GroupBy } from '@/components/GroupByToggle.vue';
  import ComboTimeSeriesChart, { type ChartEntry, type ChartMeasurementPoint } from '@/components/ComboTimeSeriesChart.vue';
  import SummaryTable from '@/components/SummaryTable.vue';
  import type { Segment } from '@/types/location';
  import type { MeasurementSubtype } from '@/types/measurementPoint';
  import type {
    LiveMeasurementPoint,
    // MeasurementPointGroup,
    AggregationLevel,
  } from '@/types/analytics';
  import type { WeatherStationApiMetric } from '@/types/weather';

  const { currentSite, pageProps } = useAuth<{
    segments: Segment[];
    measurement_points: LiveMeasurementPoint[];
    measurement_subtypes: MeasurementSubtype[];
    weather_station_api_metrics: WeatherStationApiMetric[];
  }>();
  const { segments } = pageProps.value;
  const allMeasurementPoints = pageProps.value.measurement_points;
  const weatherStationApiMetrics = pageProps.value.weather_station_api_metrics;

  // Filters
  const selectedSegmentId = ref<Segment['id'] | null>(null);
  const today = new Date().toISOString().slice(0, 10);
  const dateRange = ref<DateRange>({ start: today, end: today });
  const aggregationLevel = ref<AggregationLevel>('hourly');
  const groupBy = ref<GroupBy>('measurement_subtype');

  const isSingleDay = computed(() => dateRange.value.start === dateRange.value.end);

  // Analytics data
  const analytics = useAnalyticsData();
  const weatherAnalytics = useWeatherAnalyticsData();

  // Filtered measurement points
  const filteredMeasurementPoints = computed<LiveMeasurementPoint[]>(() => {
    if (selectedSegmentId.value === null)
      return allMeasurementPoints;

    return allMeasurementPoints.filter(
      (mp) => mp.segment_id === selectedSegmentId.value
    );
  });

  // Grouped
  type MeasurementPointGroup = {
    key: string;
    label: string;
    measurementPoints: ChartMeasurementPoint[];
  };

  const groups = computed<MeasurementPointGroup[]>(() => {
    const mps = filteredMeasurementPoints.value;

    let groupsResult: MeasurementPointGroup[] = [];
    switch (groupBy.value) {
      case 'measurement_subtype':
        groupsResult = groupByMeasurementTypeFn(mps);
        break;
      case 'segment':
        groupsResult = groupBySegmentFn(mps);
        break;
      default:
        break;
    }

    const weatherMeasurementTypeGrouped = Object.groupBy(
      weatherStationApiMetrics,
      (metric) => metric.measurement_subtype.measurement_type.name
    );
    Object.entries(weatherMeasurementTypeGrouped).forEach(([weatherMeasurementTypeName, metrics]) => {
      const existingGroup = groupsResult.find((group) => group.key === weatherMeasurementTypeName);
      if (!existingGroup && metrics) {
        const pseudoWeatherMps: MeasurementPointGroup = {
          key: weatherMeasurementTypeName,
          label: weatherMeasurementTypeName,
          measurementPoints: metrics.map((metric) => ({
            id: -metric.id, // Negative ID to avoid conflicts
            name: `🌤️ ${metric.label}`,
            effective_unit: metric.effective_unit,
            effective_chart_type: metric.measurement_subtype.default_chart_type,
            effective_color: metric.measurement_subtype.default_color,
            value_format: 'numeric',
            measurement_subtype: {
              value_type: metric.measurement_subtype.value_type,
            }
          }))
        };
        groupsResult.unshift(pseudoWeatherMps);
      }
    });

    return groupsResult;
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
      return {
        key,
        label: segment?.name ?? 'Unassigned',
        measurementPoints: groupMps
      };
    });
  }

  function groupByMeasurementTypeFn(mps: LiveMeasurementPoint[]): MeasurementPointGroup[] {
    const map = new Map<string, { mps: LiveMeasurementPoint[]; position: number }>();
    for (const mp of mps) {
      const type = mp.measurement_subtype?.measurement_type;
      const typeName = type?.name ?? 'Unknown';
      if (!map.has(typeName))
        map.set(typeName, { mps: [], position: type?.position ?? Infinity });
      map.get(typeName)!.mps.push(mp);
    }
    return Array.from(map.entries())
      .sort(([, a], [, b]) => a.position - b.position)
      .map(([key, { mps: groupMps }]) => ({
        key,
        label: key,
        measurementPoints: groupMps.sort((a, b) => {
          const posA = a.measurement_subtype?.position ?? Infinity;
          const posB = b.measurement_subtype?.position ?? Infinity;
          return posA - posB;
        }),
      }));
  }

  // Build chart entries for the combo chart — include weather overlay series
  function chartEntries(mps: ChartMeasurementPoint[]): ChartEntry[] {
    const mpEntries: ChartEntry[] = mps.map((mp) => {
      if (mp.id < 0) {
        const weatherStationApiMetricId = -mp.id;
        const hourlyData = weatherAnalytics.aggregations.value[weatherStationApiMetricId] ?? [];
        const rawData = weatherAnalytics.rawValues.value[weatherStationApiMetricId] ?? [];

        const mappedHourly = hourlyData.map((h, idx) => ({
          id: -(weatherStationApiMetricId * 10000 + idx),
          date: h.date,
          hour: h.hour,
          delta: null,
          avg_value: h.value ?? h.avg_value,
          time_on_seconds: null,
          time_off_seconds: null
        }));

        // Map weather raw values to RawValue shape
        const mappedRaw = rawData.map((r, idx) => ({
          id: -(weatherStationApiMetricId * 10000 + idx),
          scaled_value: r.scaled_value,
          sample_time: r.sample_time
        }));

        return {
          mp,
          hourlyData: aggregationLevel.value === 'hourly' ? mappedHourly : [],
          rawData: aggregationLevel.value === 'raw' ? mappedRaw : [],
        } as ChartEntry;
      }

      return {
        mp,
        hourlyData: aggregationLevel.value === 'hourly'
          ? (analytics.aggregations.value[mp.id] ?? [])
          : [],
        rawData: aggregationLevel.value === 'raw'
          ? (analytics.rawValues.value[mp.id] ?? [])
          : [],
      }
    });

    return mpEntries;
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

    // Fetch weather data in parallel if metrics are selected
    await loadWeatherData();
  }

  async function loadWeatherData() {
    if (weatherStationApiMetrics.length === 0) {
      weatherAnalytics.clear();
      return;
    }

    if (aggregationLevel.value === 'raw' && isSingleDay.value) {
      const startTime = `${dateRange.value.start}T00:00:00`;
      const endTime = `${dateRange.value.end}T23:59:59`;
      await weatherAnalytics.fetchRaw(startTime, endTime);
    } else
      await weatherAnalytics.fetchHourly(dateRange.value);
  }

  // Auto-correct aggregation level
  watch(isSingleDay, (single) => {
    if (!single && aggregationLevel.value === 'raw')
      aggregationLevel.value = 'hourly';
  });

  // Reload on filter changes
  watch(
    [dateRange, aggregationLevel, selectedSegmentId],
    () => { loadData(); },
    { immediate: true }
  );
</script>
