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
          <div v-if="hasWeatherStationApiMetrics" class="col-auto">
            <WeatherOverlayToggle
              v-model="selectedWeatherStationApiMetricIds"
              :weatherStationApiMetrics="weatherStationApiMetrics" />
          </div>
        </div>
      </CCardBody>
    </CCard>

    <!-- Loading -->
    <div v-if="analytics.loading.value || weatherAnalytics.loading.value" class="text-center py-5">
      <CSpinner color="primary" />
      <p class="mt-2 text-body-secondary">Loading analytics data...</p>
    </div>

    <!-- Error -->
    <CAlert v-else-if="analytics.error.value" color="danger" class="mb-4">
      {{ analytics.error.value }}
    </CAlert>
    <CAlert v-else-if="weatherAnalytics.error.value" color="danger" class="mb-4">
      {{ weatherAnalytics.error.value }}
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
            {{ group.serieDefinitions.length }}
          </CBadge>
        </h5>

        <!-- Single combo chart for all measurement points in the group, with weather overlay -->
        <CCard class="mb-4 shadow-sm">
          <CCardBody>
            <ComboTimeSeriesChart :entries="chartEntries(group.serieDefinitions)" />
          </CCardBody>
        </CCard>

        <!-- Summary table for all measurement points in the group -->
        <CCard class="mb-4 shadow-sm">
          <CCardHeader>
            <h6 class="mb-0">Summary</h6>
          </CCardHeader>
          <CCardBody>
            <SummaryTable :rows="buildSummaryData(group)" />
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
  import WeatherOverlayToggle from './components/WeatherOverlayToggle.vue';
  import ComboTimeSeriesChart, { type ChartEntry, type SerieDefinition } from '@/components/ComboTimeSeriesChart.vue';
  import SummaryTable, { type RowDefinition } from '@/components/SummaryTable.vue';
  import { mapMeasurementPointToSerieDefinition } from '@/utils/valueFormaters';
  import type { Segment } from '@/types/location';
  import type { MeasurementSubtype } from '@/types/measurementPoint';
  import type { LiveMeasurementPoint, AggregationLevel } from '@/types/analytics';
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
  const selectedWeatherStationApiMetricIds = ref<WeatherStationApiMetric['id'][]>([]);

  const isSingleDay = computed(() => dateRange.value.start === dateRange.value.end);
  const hasWeatherStationApiMetrics = computed(() => weatherStationApiMetrics.length > 0);

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
    serieDefinitions: SerieDefinition[];
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

    const weatherOverlaySerieDefinitions: SerieDefinition[] = weatherStationApiMetrics
      .filter((metric) => selectedWeatherStationApiMetricIds.value.includes(metric.id))
      .map((metric) => ({
        id: -metric.id, // Negative ID to avoid conflicts with measurement points
        name: `🌤️ ${metric.label}`,
        unit: metric.unit,
        chart_type: metric.measurement_subtype.default_chart_type,
        color: metric.measurement_subtype.default_color,
        value_format: 'numeric',
        value_type: metric.measurement_subtype.value_type
      }));

    groupsResult.forEach((group) => {
      group.serieDefinitions.push(...weatherOverlaySerieDefinitions);
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
        serieDefinitions: groupMps.map(mapMeasurementPointToSerieDefinition)
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
        serieDefinitions: groupMps.sort((a, b) => {
          const posA = a.measurement_subtype?.position ?? Infinity;
          const posB = b.measurement_subtype?.position ?? Infinity;
          return posA - posB;
        }).map(mapMeasurementPointToSerieDefinition),
      }));
  }

  // Build chart entries for the combo chart — include weather overlay series
  function chartEntries(serieDefinitions: SerieDefinition[]): ChartEntry[] {
    const mpEntries: ChartEntry[] = serieDefinitions.map((serieDefinition) => {
      if (serieDefinition.id < 0) {
        const weatherStationApiMetricId = -serieDefinition.id;
        const hourlyData = weatherAnalytics.aggregations.value[weatherStationApiMetricId] ?? [];
        const rawData = weatherAnalytics.rawValues.value[weatherStationApiMetricId] ?? [];

        return {
          serieDefinition,
          hourlyData: aggregationLevel.value === 'hourly' ? hourlyData : [],
          rawData: aggregationLevel.value === 'raw' ? rawData : [],
        } as ChartEntry;
      }

      return {
        serieDefinition,
        hourlyData: aggregationLevel.value === 'hourly'
          ? (analytics.aggregations.value[serieDefinition.id] ?? [])
          : [],
        rawData: aggregationLevel.value === 'raw'
          ? (analytics.rawValues.value[serieDefinition.id] ?? [])
          : []
      }
    });

    return mpEntries;
  }

  function buildSummaryData(group: MeasurementPointGroup): RowDefinition[] {
    return group.serieDefinitions.map((serieDefinition) => {
      if (serieDefinition.id < 0) {
        const weatherStationApiMetricId = -serieDefinition.id;
        const summary = weatherAnalytics.summary.value[weatherStationApiMetricId] || {};

        return { ...serieDefinition, summary };
      }

      const summary = analytics.summary.value[serieDefinition.id] || {};
      return { ...serieDefinition, summary };
    });
  }

  // Data fetching
  async function loadData() {
    const mpIds = filteredMeasurementPoints.value.map((mp) => mp.id);

    const hasMP = mpIds.length > 0;
    const hasWeather = weatherStationApiMetrics.length > 0;

    if (!hasMP && !hasWeather) {
      analytics.clear();
      weatherAnalytics.clear();
      return;
    }

    const promises: Promise<any>[] = [];

    if (aggregationLevel.value === 'raw' && isSingleDay.value) {
      const startTime = `${dateRange.value.start}T00:00:00`;
      const endTime = `${dateRange.value.end}T23:59:59`;

      if (hasMP)
        promises.push(analytics.fetchRaw(mpIds, startTime, endTime));

      if (hasWeather)
        promises.push(weatherAnalytics.fetchRaw(startTime, endTime));
    } else {
      if (hasMP)
        promises.push(analytics.fetchHourly(mpIds, dateRange.value));

      if (hasWeather)
        promises.push(weatherAnalytics.fetchHourly(dateRange.value));
    }

    await Promise.all(promises);
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
