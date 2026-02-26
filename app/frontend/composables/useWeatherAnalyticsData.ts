import { ref } from 'vue';
import axios from 'axios';
import { useApiCall } from '@/composables/useApi';
import { ROUTES } from '@/types/permissions';
import type {
  WeatherStationApiHourlyAggregation,
  WeatherStationApiRawValue,
  WeatherStationApiMetric
} from '@/types/weather';

type Aggregations = Record<WeatherStationApiMetric['id'], WeatherStationApiHourlyAggregation[]>;
type RawValues = Record<WeatherStationApiMetric['id'], WeatherStationApiRawValue[]>;

type HourlyResponse = {
  aggregations: Aggregations;
};

type RawValueResponse = {
  raw_values: RawValues;
};

export function useWeatherAnalyticsData() {
  const aggregations = ref<Aggregations>({});
  const rawValues = ref<RawValues>({});
  const loading = ref(false);
  const error = ref<string | null>(null);

  const { execute } = useApiCall();

  async function fetchHourly(dateRange: { start: string; end: string }) {
    error.value = null;
    loading.value = true;

    const { success, error: apiError, data } = await execute<HourlyResponse>(
      () => axios.get(
        ROUTES.analytics_weather_hourly.path,
        {
          params: {
            start_date: dateRange.start,
            end_date: dateRange.end
          }
        }
      ),
      { errorTitle: 'Load Weather Analytics Error', showErrorToast: true }
    );

    if (success)
      aggregations.value = data.aggregations;

    if (apiError)
      error.value = apiError.error;

    loading.value = false;
  }

  async function fetchRaw(startTime: string, endTime: string) {
    const { success, error: apiError, data } = await execute<RawValueResponse>(
      () => axios.get(
        ROUTES.analytics_weather_raw.path,
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
    error.value = null;
  }

  return {
    aggregations,
    rawValues,
    loading,
    error,
    fetchHourly,
    fetchRaw,
    clear
  };
}
