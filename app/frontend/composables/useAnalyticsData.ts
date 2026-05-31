import { ref } from 'vue';
import axios from 'axios';
import { useApiCall } from '@/composables/useApi';
import useAuth from '@/composables/useAuth';
import type {
  AnalyticsSummary,
  HourlyAggregation,
  RawValue
} from '@/types/analytics';
import type { MeasurementPoint } from '@/types/measurementPoint';

type Aggregations = Record<MeasurementPoint['id'], HourlyAggregation[]>;
type RawValues = Record<MeasurementPoint['id'], RawValue[]>;
type Summary = Record<MeasurementPoint['id'], AnalyticsSummary>;

type HourlyResponse = {
  aggregations: Aggregations;
  summary: Summary;
};

type RawValueResponse = {
  raw_values: RawValues;
};

export function useAnalyticsData() {
  const aggregations = ref<Aggregations>({});
  const rawValues = ref<RawValues>({});
  const summary = ref<Summary>({});
  const loading = ref(false);
  const error = ref<string | null>(null);

  const { execute } = useApiCall();
  const { routePath } = useAuth();

  async function fetchHourly(
    mpIds: MeasurementPoint['id'][],
    dateRange: { start: string; end: string }
  ) {
    if (mpIds.length === 0) {
      aggregations.value = {};
      summary.value = {};
      return;
    }

    error.value = null;
    loading.value = true;

    const { success, error: apiError, data } = await execute<HourlyResponse>(
      () => axios.get(
        routePath('analytics_hourly'),
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
    if (mpIds.length === 0) {
      rawValues.value = {};
      return;
    }

    error.value = null;
    loading.value = true;

    const { success, error: apiError, data } = await execute<RawValueResponse>(
      () => axios.get(
        routePath('analytics_raw'),
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
