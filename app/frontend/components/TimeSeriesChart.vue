<template>
  <div class="time-series-chart">
    <div v-if="!hasData" class="empty-state text-center py-5">
      <CIcon name="cil-chart-line" size="xl" class="text-body-secondary mb-2" />
      <p class="text-body-secondary mb-0">No data available for the selected period</p>
    </div>
    <apexchart
      v-else
      :type="apexChartType"
      :height="height"
      :options="chartOptions"
      :series="chartSeries" />
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import type { HourlyAggregation, RawValue } from '@/types/analytics';
  import type { ValueType } from '@/types/measurementPoint';

  type ApexChartType = 'line'
    | 'area'
    | 'bar'
    | 'rangeBar'

  type ChartThresholds = {
    alarm_low: number | null;
    alarm_high: number | null;
    warning_low: number | null;
    warning_high: number | null;
  };

  const {
    hourlyData = [],
    rawData = [],
    valueType,
    chartType,
    color = '#059669',
    unit = '',
    thresholds = null,
    height = 320,
    title = ''
  } = defineProps<{
    hourlyData?: HourlyAggregation[];
    rawData?: RawValue[];
    valueType: ValueType;
    chartType?: ApexChartType | null;
    color?: string;
    unit?: string;
    thresholds?: ChartThresholds | null;
    height?: number;
    title?: string;
  }>();

  const hasData = computed(() => hourlyData.length > 0 || rawData.length > 0);
  const isRaw = computed(() => rawData.length > 0);

  const apexChartType = computed(() => {
    if (chartType)
      return chartType;

    if (valueType === 'accumulative')
      return 'bar';

    if (valueType === 'status')
      return 'rangeBar';

    return 'line';
  });

  const chartSeries = computed(() => {
    if (valueType === 'instantaneous')
      return buildInstantaneousSeries();

    if (valueType === 'accumulative')
      return buildAccumulativeSeries();

    return buildStatusSeries();

  });

  function buildInstantaneousSeries() {
    if (isRaw.value) {
      return [
        {
          name: title || 'Value',
          type: 'line',
          data: rawData.map((rv) => ({
            x: new Date(rv.sample_time).getTime(),
            y: rv.scaled_value
          }))
        }
      ];
    }

    const avgData = hourlyData.map((h) => ({
      x: hourToTimestamp(h.date, h.hour),
      y: h.avg_value
    }));

    const series: any[] = [
      { name: title || 'Average', type: 'line', data: avgData }
    ];

    // Add min/max range if available
    const rangeData = hourlyData
      .filter((h) => h.min_value !== null && h.max_value !== null)
      .map((h) => ({
        x: hourToTimestamp(h.date, h.hour),
        y: [h.min_value, h.max_value]
      }));

    if (rangeData.length > 0) {
      series.push({
        name: 'Min/Max Range',
        type: 'rangeArea',
        data: rangeData
      });
    }

    return series;
  }

  function buildAccumulativeSeries() {
    if (isRaw.value) {
      return [
        {
          name: title || 'Value',
          data: rawData.map((rv) => ({
            x: new Date(rv.sample_time).getTime(),
            y: rv.scaled_value
          }))
        }
      ];
    }

    return [
      {
        name: title || 'Consumption',
        data: hourlyData.map((h) => ({
          x: hourToTimestamp(h.date, h.hour),
          y: h.delta ?? 0
        }))
      }
    ];
  }

  function buildStatusSeries() {
    if (isRaw.value) {
      // Build on/off segments from raw transitions
      const segments: { x: string; y: [number, number]; fillColor: string }[] = [];
      for (let i = 0; i < rawData.length - 1; i++) {
        const current = rawData[i];
        const next = rawData[i + 1];
        const isOn = current.scaled_value > 0;
        segments.push({
          x: title || 'Status',
          y: [
            new Date(current.sample_time).getTime(),
            new Date(next.sample_time).getTime()
          ],
          fillColor: isOn ? '#10b981' : '#d1d5db'
        });
      }
      return [{ data: segments }];
    }

    // Build segments from hourly data
    const segments = hourlyData.map((h) => {
      const start = hourToTimestamp(h.date, h.hour);
      const end = start + 3600000; // +1 hour
      const onRatio =
        h.time_on_seconds !== null && h.time_off_seconds !== null
          ? h.time_on_seconds / (h.time_on_seconds + h.time_off_seconds)
          : 0;
      return {
        x: title || 'Status',
        y: [start, end],
        fillColor: onRatio > 0.5 ? '#10b981' : onRatio > 0 ? '#fbbf24' : '#d1d5db'
      };
    });

    return [{ data: segments }];
  }

  function hourToTimestamp(date: string, hour: number): number {
    return new Date(`${date}T${String(hour).padStart(2, '0')}:00:00`).getTime();
  }

  const thresholdAnnotations = computed(() => {
    if (!thresholds)
      return [];

    const annotations: any[] = [];
    const addLine = (value: number | null, label: string, color: string, dash: number) => {
      if (value === null)
        return;

      annotations.push({
        y: value,
        borderColor: color,
        strokeDashArray: dash,
        label: {
          text: `${label}: ${value}`,
          borderColor: color,
          style: { color: '#fff', background: color, fontSize: '10px' }
        }
      });
    };

    addLine(thresholds.alarm_high, 'Alarm High', '#ef4444', 0);
    addLine(thresholds.alarm_low, 'Alarm Low', '#ef4444', 0);
    addLine(thresholds.warning_high, 'Warning High', '#f59e0b', 4);
    addLine(thresholds.warning_low, 'Warning Low', '#f59e0b', 4);

    return annotations;
  });

  const chartOptions = computed(() => {
    const base: any = {
      chart: {
        toolbar: { show: true, tools: { download: true, zoom: true, pan: true, reset: true } },
        zoom: { enabled: true },
        fontFamily: 'inherit'
      },
      colors: [color, `${color}33`],
      stroke: { curve: 'smooth', width: valueType === 'accumulative' ? 0 : 2 },
      xaxis: {
        type: 'datetime',
        labels: { datetimeUTC: false, style: { fontSize: '11px' } }
      },
      yaxis: {
        labels: {
          formatter: (val: number) => {
            if (val === null || val === undefined) return '';
            return unit ? `${Number(val.toFixed(2))} ${unit}` : String(Number(val.toFixed(2)));
          },
          style: { fontSize: '11px' }
        },
        title: { text: unit || undefined, style: { fontSize: '12px' } }
      },
      tooltip: {
        x: { format: 'dd MMM yyyy HH:mm' },
        shared: true
      },
      grid: {
        borderColor: '#e5e7eb',
        strokeDashArray: 3
      },
      annotations: {
        yaxis: thresholdAnnotations.value
      },
      dataLabels: { enabled: false },
      legend: { show: true, position: 'top' }
    };

    if (valueType === 'accumulative') {
      base.plotOptions = {
        bar: { borderRadius: 3, columnWidth: '60%' }
      };
    }

    if (valueType === 'status') {
      base.plotOptions = {
        rangeBar: { horizontal: true }
      };
      base.yaxis = { labels: { style: { fontSize: '11px' } } };
      base.xaxis = { type: 'datetime', labels: { datetimeUTC: false } };
    }

    return base;
  });
</script>

<style scoped>
  .empty-state {
    color: #9ca3af;
  }
</style>
