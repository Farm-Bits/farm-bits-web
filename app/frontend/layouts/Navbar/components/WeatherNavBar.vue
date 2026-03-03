<template>
  <div v-if="hasAnyData" class="weather-nav d-flex align-items-center gap-3">
    <!-- Sun data -->
    <div v-if="sunData" class="weather-nav__sun d-flex align-items-center gap-2">
      <span class="weather-nav__icon" title="Sunrise">☀️</span>
      <span class="weather-nav__value">{{ formatTime(sunData.sunrise) }}</span>
      <span class="weather-nav__separator">–</span>
      <span class="weather-nav__icon" title="Sunset">🌅</span>
      <span class="weather-nav__value">{{ formatTime(sunData.sunset) }}</span>
      <span v-if="dayLengthFormatted" class="weather-nav__day-length text-body-secondary">
        ({{ dayLengthFormatted }})
      </span>
    </div>

    <span v-if="sunData && hasWeatherReadings" class="weather-nav__divider">|</span>

    <!-- Weather readings -->
    <div v-if="hasWeatherReadings" class="weather-nav__readings d-flex align-items-center gap-3">
      <div
        v-for="weatherReading in weatherData"
        :key="weatherReading.key"
        class="weather-nav__reading d-flex align-items-center gap-1"
        :title="`${weatherReading.label} — ${weatherStaleText(weatherReading)}`">
        <span class="weather-nav__reading-icon">{{ metricIcon(weatherReading.key) }}</span>
        <span class="weather-nav__reading-value">
          {{ formatReading(weatherReading) }}
        </span>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed, onMounted, ref } from 'vue';
  import axios from 'axios';
  import { useApiCall } from '@/composables/useApi';
  import { useLivePolling } from '@/composables/useLivePolling';
  import { ROUTES } from '@/types/permissions';
  import type { SunData } from '@/types/weather';

  type WeatherReading = {
    key: string;
    label: string;
    value: number | null;
    unit: string;
    sample_time: string;
  };

  type PollResponse = {
    weather_data: WeatherReading[] | null;
    sun_data: SunData | null;
  };

  const { execute } = useApiCall();

  const weatherData = ref<WeatherReading[] | null>(null);
  const sunData = ref<SunData | null>(null);

  const hasWeatherReadings = computed(() => {
    return weatherData.value && weatherData.value.length > 0;
  });

  const hasAnyData = computed(() => {
    return sunData.value || hasWeatherReadings.value;
  });

  const dayLengthFormatted = computed(() => {
    if (!sunData.value?.day_length_seconds)
      return null;

    const total = sunData.value.day_length_seconds;
    const hours = Math.floor(total / 3600);
    const minutes = Math.floor((total % 3600) / 60);
    return `${hours}h ${minutes}m`;
  });

  // Polling
  async function fetchPollData() {
    const { success, data } = await execute<PollResponse>(
      () => axios.get(ROUTES.live_poll_weather.path)
    );

    if (success) {
      weatherData.value = data.weather_data;
      sunData.value = data.sun_data;
    }
  }

  const polling = useLivePolling(
    fetchPollData,
    {
      intervalMs: 600000, // 10 minutes
      immediate: false
    }
  );

  polling.start();

  function metricIcon(key: string) {
    const icons: Record<string, string> = {
      temperature: '🌡️',
      humidity: '💧',
      wind_speed: '💨',
      precipitation: '🌧️',
      global_radiation: '☀️',
      barometric_pressure: '🔵',
    };
    return icons[key] ?? '📊';
  }

  function formatReading(reading: WeatherReading) {
    if (reading.value === null)
      return '—';

    const val = Number(reading.value.toFixed(1));
    return `${val}${reading.unit}`;
  }

  function formatTime(timeStr: string) {
    // timeStr is "HH:MM:SS", display as "HH:MM"
    if (!timeStr)
      return '';

    return timeStr.slice(0, 5);
  }

  function weatherStaleText(reading: WeatherReading) {
    if (!reading.sample_time)
      return '';

    const diff = Date.now() - new Date(reading.sample_time).getTime();
    const minutes = Math.round(diff / 60000);

    if (minutes < 1)
      return 'just now';

    if (minutes < 60)
      return `${minutes}m ago`;

    const hours = Math.floor(minutes / 60);
    return `${hours}h ago`;
  }

  onMounted(() => {
    fetchPollData();
  });
</script>

<style scoped>
  .weather-nav {
    font-size: 0.8125rem;
    line-height: 1;
    white-space: nowrap;
    margin-left: 50px;
  }

  .weather-nav__icon {
    font-size: 0.875rem;
  }

  .weather-nav__value {
    font-weight: 500;
    color: var(--cui-body-color);
  }

  .weather-nav__separator {
    color: var(--cui-tertiary-color);
    font-size: 0.75rem;
  }

  .weather-nav__day-length {
    font-size: 0.75rem;
  }

  .weather-nav__divider {
    color: var(--cui-border-color);
    font-size: 0.875rem;
  }

  .weather-nav__reading-icon {
    font-size: 0.8125rem;
  }

  .weather-nav__reading-value {
    font-weight: 500;
    font-size: 0.8125rem;
    color: var(--cui-body-color);
  }
</style>
