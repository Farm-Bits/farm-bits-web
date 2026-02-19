<template>
  <div class="status-timeline">
    <div v-if="segments.length === 0" class="text-center py-4 text-body-secondary">
      No status data available
    </div>
    <div v-else>
      <div class="timeline-bar-container">
        <div class="timeline-bar">
          <div
            v-for="(seg, idx) in segments"
            :key="idx"
            class="timeline-segment"
            :style="{
              width: seg.widthPercent + '%',
              backgroundColor: seg.isOn ? '#10b981' : '#d1d5db',
            }"
            :title="seg.tooltip" />
        </div>
        <div class="timeline-labels d-flex justify-content-between mt-1">
          <span class="small text-body-secondary">{{ timeLabels.start }}</span>
          <span class="small text-body-secondary">{{ timeLabels.end }}</span>
        </div>
      </div>
      <div class="timeline-legend d-flex gap-3 mt-2">
        <span class="d-flex align-items-center gap-1 small">
          <span class="legend-dot" style="background-color: #10b981;" /> On: {{ formatDuration(totalOnSeconds) }}
        </span>
        <span class="d-flex align-items-center gap-1 small">
          <span class="legend-dot" style="background-color: #d1d5db;" /> Off: {{ formatDuration(totalOffSeconds) }}
        </span>
        <span v-if="onPercentage !== null" class="small text-body-secondary">
          ({{ onPercentage }}% on)
        </span>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import type { HourlyAggregation, RawValue } from '@/types/analytics';

  const {
    hourlyData = [],
    rawData = [],
  } = defineProps<{
    hourlyData?: HourlyAggregation[];
    rawData?: RawValue[];
  }>();

  interface TimelineSegment {
    isOn: boolean;
    durationSeconds: number;
    widthPercent: number;
    tooltip: string;
  }

  const isRaw = computed(() => rawData.length > 0);

  const segments = computed<TimelineSegment[]>(() => {
    if (isRaw.value)
      return buildRawSegments();

    return buildHourlySegments();
  });

  function buildHourlySegments(): TimelineSegment[] {
    if (hourlyData.length === 0)
      return [];

    const totalSeconds = hourlyData.reduce((sum, h) => {
      return sum + (h.time_on_seconds ?? 0) + (h.time_off_seconds ?? 0);
    }, 0);

    if (totalSeconds === 0)
      return [];

    const result: TimelineSegment[] = [];
    for (const h of hourlyData) {
      const onSec = h.time_on_seconds ?? 0;
      const offSec = h.time_off_seconds ?? 0;
      const hourLabel = `${h.date} ${String(h.hour).padStart(2, '0')}:00`;

      if (onSec > 0)
        result.push({
          isOn: true,
          durationSeconds: onSec,
          widthPercent: (onSec / totalSeconds) * 100,
          tooltip: `${hourLabel} — On: ${formatDuration(onSec)}`,
        });

      if (offSec > 0)
        result.push({
          isOn: false,
          durationSeconds: offSec,
          widthPercent: (offSec / totalSeconds) * 100,
          tooltip: `${hourLabel} — Off: ${formatDuration(offSec)}`,
        });
    }
    return result;
  }

  function buildRawSegments(): TimelineSegment[] {
    if (rawData.length < 2)
      return [];

    const firstTime = new Date(rawData[0].sample_time).getTime();
    const lastTime = new Date(rawData[rawData.length - 1].sample_time).getTime();
    const totalMs = lastTime - firstTime;

    if (totalMs === 0)
      return [];

    const result: TimelineSegment[] = [];
    for (let i = 0; i < rawData.length - 1; i++) {
      const current = rawData[i];
      const next = rawData[i + 1];
      const startMs = new Date(current.sample_time).getTime();
      const endMs = new Date(next.sample_time).getTime();
      const durationMs = endMs - startMs;
      const isOn = current.scaled_value > 0;

      result.push({
        isOn,
        durationSeconds: Math.round(durationMs / 1000),
        widthPercent: (durationMs / totalMs) * 100,
        tooltip: `${formatTime(current.sample_time)} → ${formatTime(next.sample_time)} — ${isOn ? 'On' : 'Off'}`,
      });
    }
    return result;
  }

  const totalOnSeconds = computed(() => {
    return segments.value
      .filter((s) => s.isOn)
      .reduce((sum, s) => sum + s.durationSeconds, 0);
  });

  const totalOffSeconds = computed(() => {
    return segments.value
      .filter((s) => !s.isOn)
      .reduce((sum, s) => sum + s.durationSeconds, 0);
  });

  const onPercentage = computed(() => {
    const total = totalOnSeconds.value + totalOffSeconds.value;
    if (total === 0)
      return null;

    return Math.round((totalOnSeconds.value / total) * 100);
  });

  const timeLabels = computed(() => {
    if (isRaw.value && rawData.length > 0)
      return {
        start: formatTime(rawData[0].sample_time),
        end: formatTime(rawData[rawData.length - 1].sample_time),
      };

    if (hourlyData.length > 0) {
      const first = hourlyData[0];
      const last = hourlyData[hourlyData.length - 1];
      return {
        start: `${first.date} ${String(first.hour).padStart(2, '0')}:00`,
        end: `${last.date} ${String(last.hour).padStart(2, '0')}:59`,
      };
    }
    return { start: '', end: '' };
  });

  function formatDuration(seconds: number): string {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    if (h > 0)
      return `${h}h ${m}m`;

    if (m > 0)
      return `${m}m ${s}s`;

    return `${s}s`;
  }

  function formatTime(iso: string): string {
    const d = new Date(iso);
    return d.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  }
</script>

<style scoped>
  .timeline-bar-container {
    padding: 0.5rem 0;
  }

  .timeline-bar {
    display: flex;
    height: 24px;
    border-radius: 4px;
    overflow: hidden;
    border: 1px solid #e5e7eb;
  }

  .timeline-segment {
    transition: opacity 0.2s;
    cursor: default;
  }

  .timeline-segment:hover {
    opacity: 0.8;
  }

  .legend-dot {
    display: inline-block;
    width: 10px;
    height: 10px;
    border-radius: 50%;
  }
</style>
