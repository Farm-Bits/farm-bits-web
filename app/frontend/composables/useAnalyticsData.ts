import { ref } from 'vue';
import axios from 'axios';
import { useApiCall } from '@/composables/useApi';
import { ROUTES } from '@/types/permissions';
import type {
  AnalyticsSummary,
  HourlyAggregation,
  RawValue
} from '@/types/analytics';
import type { MeasurementPoint } from '@/types/measurementPoint';

type HourlyResponse = {
  aggregations: Record<MeasurementPoint['id'], HourlyAggregation[]>;
  summary: Record<MeasurementPoint['id'], AnalyticsSummary>;
};

type RawResponse = {
  raw_values: Record<MeasurementPoint['id'], RawValue[]>;
};

export function useAnalyticsData() {
  const aggregations = ref<Record<MeasurementPoint['id'], HourlyAggregation[]>>({});
  const rawValues = ref<Record<MeasurementPoint['id'], RawValue[]>>({});
  const summary = ref<Record<MeasurementPoint['id'], AnalyticsSummary>>({});
  const loading = ref(false);
  const error = ref<string | null>(null);

  const { execute } = useApiCall();

  async function fetchHourly(
    mpIds: MeasurementPoint['id'][],
    dateRange: { start: string; end: string }
  ) {
    if (mpIds.length === 0)
      return;

    error.value = null;
    loading.value = true;

    const { success, error: apiError, data } = await execute<HourlyResponse>(
      () => axios.get(
        ROUTES.analytics_hourly.path,
        {
          params: {
            measurement_point_ids: mpIds,
            start_date: dateRange.start,
            end_date: dateRange.end,
          }
        }
      ),
      { errorTitle: 'Load Hourly Analytics Error', showErrorToast: true }
    );

    if (success) {
      aggregations.value = data.aggregations;
      summary.value = data.summary;
    }

    if (apiError)
      error.value = apiError.error;

    loading.value = false;
  }

  async function fetchRaw(
    mpIds: MeasurementPoint['id'][],
    startTime: string,
    endTime: string
  ): Promise<void> {
    if (mpIds.length === 0)
      return;

    error.value = null;
    loading.value = true;

    const { success, error: apiError, data } = await execute<RawResponse>(
      () => axios.get(
        ROUTES.analytics_raw.path,
        {
          params: {
            measurement_point_ids: mpIds,
            start_time: startTime,
            end_time: endTime,
          }
        }
      ),
      { errorTitle: 'Load Raw Analytics Error', showErrorToast: true }
    );

    if (success)
      rawValues.value = data.raw_values;

    if (apiError)
      error.value = apiError.error;

    loading.value = false;
  }

  function clear(): void {
    aggregations.value = {};
    rawValues.value = {};
    summary.value = {};
    error.value = null;
  }

  return {
    aggregations,
    rawValues,
    summary,
    loading,
    error,
    fetchHourly,
    fetchRaw,
    clear,
  };
}
