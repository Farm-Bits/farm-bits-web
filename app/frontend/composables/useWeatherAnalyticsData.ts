import { ref } from 'vue';
import axios from 'axios';
import { useApiCall } from '@/composables/useApi';
import useAuth from '@/composables/useAuth';
import type {
  WeatherStationApiHourlyAggregation,
  WeatherStationApiMetric,
  WeatherStationApiRawValue,
  WeatherStationApiSummary
} from '@/types/weather';

type Aggregations = Record<WeatherStationApiMetric['id'], WeatherStationApiHourlyAggregation[]>;
type RawValues = Record<WeatherStationApiMetric['id'], WeatherStationApiRawValue[]>;
type Summary = Record<WeatherStationApiMetric['id'], WeatherStationApiSummary>;

type HourlyResponse = {
  aggregations: Aggregations;
  summary: Summary;
};

type RawValueResponse = {
  raw_values: RawValues;
};

export function useWeatherAnalyticsData() {
  const aggregations = ref<Aggregations>({});
  const rawValues = ref<RawValues>({});
  const summary = ref<Summary>({});
  const loading = ref(false);
  const error = ref<string | null>(null);

  const { execute } = useApiCall();
  const { routePath } = useAuth();

  async function fetchHourly(dateRange: { start: string; end: string }) {
    error.value = null;
    loading.value = true;

    const { success, error: apiError, data } = await execute<HourlyResponse>(
      () => axios.get(
        routePath('analytics_weather_hourly'),
        {
          params: {
            start_date: dateRange.start,
            end_date: dateRange.end
          }
        }
      ),
      { errorTitle: 'Load Weather Analytics Error', showErrorToast: true }
    );

    if (success) {
      aggregations.value = data.aggregations;
      summary.value = data.summary;
    }

    if (apiError)
      error.value = apiError.error;

    loading.value = false;
  }

  async function fetchRaw(startTime: string, endTime: string) {
    error.value = null;
    loading.value = true;

    const { success, error: apiError, data } = await execute<RawValueResponse>(
      () => axios.get(
        routePath('analytics_weather_raw'),
        {
          params: {
            start_time: startTime,
            end_time: endTime
          }
        }
      ),
      { errorTitle: 'Load Weather Raw Data Error', showErrorToast: true }
    );

    if (success)
      rawValues.value = data.raw_values;

    if (apiError)
      error.value = apiError.error;

    loading.value = false;
  }

  function clear() {
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
    clear
  };
}
