<template>
  <div class="combo-time-series-chart">
    <div v-if="!hasData" class="empty-state text-center py-5">
      <CIcon name="cil-chart-line" size="xl" class="text-body-secondary mb-2" />
      <p class="text-body-secondary mb-0">No data available for the selected period</p>
    </div>
    <VChart
      v-else
      :option="chartOption"
      :style="{ height: `${chartHeight}px` }"
      autoresize />
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import VChart from 'vue-echarts';
  import type { EChartsOption } from 'echarts';
  import { getDisplayValue } from '@/utils/valueConverters.ts';
  import type { HourlyAggregation, RawValue, LiveMeasurementPoint } from '@/types/analytics';
  import type { ChartType } from '@/types/measurementPoint';

  export type ChartEntry = {
    mp: LiveMeasurementPoint;
    hourlyData: HourlyAggregation[];
    rawData: RawValue[];
  };

  const {
    entries,
    height = 360,
  } = defineProps<{
    entries: ChartEntry[];
    height?: number;
  }>();

  // ── Partition entries ──

  const numericEntries = computed(() =>
    entries.filter((e) => {
      const vt = e.mp.measurement_subtype?.value_type;
      return vt === 'instantaneous' || vt === 'accumulative';
    })
  );

  const statusEntries = computed(() =>
    entries.filter((e) => e.mp.measurement_subtype?.value_type === 'status')
  );

  const stepEntries = computed(() =>
    statusEntries.value.filter((e) => {
      const ct = e.mp.effective_chart_type as ChartType | null;
      return !ct || ct === 'step';
    })
  );

  const rangeBarEntries = computed(() =>
    statusEntries.value.filter((e) => {
      const ct = e.mp.effective_chart_type as ChartType | null;
      return ct === 'rangeBar';
    })
  );

  const hasData = computed(() =>
    entries.some((e) => e.hourlyData.length > 0 || e.rawData.length > 0)
  );

  // Each status MP gets a band of height 1 with 0.5 gap between them
  const STATUS_BAND_HEIGHT = 1;
  const STATUS_GAP = 0.5;

  const chartHeight = computed(() => {
    const statusExtra = statusEntries.value.length * 50;
    return height + statusExtra;
  });

  // ── Colors ──

  const PALETTE = [
    '#059669', '#2563eb', '#d97706', '#dc2626', '#7c3aed',
    '#db2777', '#0891b2', '#65a30d', '#ea580c', '#4f46e5',
  ];

  const colorMap = computed(() => {
    const map = new Map<number, string>();
    let idx = 0;
    for (const entry of [...numericEntries.value, ...statusEntries.value]) {
      map.set(entry.mp.id, entry.mp.effective_color ?? PALETTE[idx % PALETTE.length]);
      idx++;
    }
    return map;
  });

  function entryColor(entry: ChartEntry): string {
    return colorMap.value.get(entry.mp.id) ?? PALETTE[0];
  }

  // ── Helpers ──

  function hourToTimestamp(date: string, hour: number): number {
    return new Date(`${date}T${String(hour).padStart(2, '0')}:00:00`).getTime();
  }

  // ── Status offset: each status MP gets a y-band ──

  function statusOffset(entry: ChartEntry): number {
    const idx = statusEntries.value.findIndex((e) => e.mp.id === entry.mp.id);
    return idx * (STATUS_BAND_HEIGHT + STATUS_GAP);
  }

  // ── Y-axis grouping by unit (for numeric series) ──

  type UnitGroup = {
    unit: string;
    entries: ChartEntry[];
    yAxisIndex: number;
  };

  const unitGroups = computed<UnitGroup[]>(() => {
    const map = new Map<string, ChartEntry[]>();
    for (const entry of numericEntries.value) {
      const unit = entry.mp.effective_unit ?? '';
      if (!map.has(unit))
        map.set(unit, []);
      map.get(unit)!.push(entry);
    }
    let idx = 0;
    return Array.from(map.entries()).map(([unit, groupEntries]) => ({
      unit,
      entries: groupEntries,
      yAxisIndex: idx++,
    }));
  });

  const statusYAxisIndex = computed(() => unitGroups.value.length);

  const statusYRange = computed(() => {
    const count = statusEntries.value.length;
    if (count === 0)
      return { min: 0, max: 1 };

    const max = count * (STATUS_BAND_HEIGHT + STATUS_GAP) - STATUS_GAP + 0.3;
    return { min: -0.3, max };
  });

  // ── Resolve series config for numeric entries ──

  function resolveSeriesConfig(entry: ChartEntry): {
    type: string;
    step?: string | false;
    areaStyle?: Record<string, any>;
  } {
    const chartType = entry.mp.effective_chart_type as ChartType | null;
    const vt = entry.mp.measurement_subtype?.value_type;
    const isRaw = entry.rawData.length > 0;

    if (chartType === 'area')
      return { type: 'line', areaStyle: { opacity: 0.3 } };

    if (chartType === 'bar' && !isRaw)
      return { type: 'bar' };

    if (chartType === 'line')
      return { type: 'line' };

    if (!chartType) {
      if (vt === 'accumulative' && !isRaw)
        return { type: 'bar' };
      return { type: 'line' };
    }

    return { type: 'line' };
  }

  // ── Build ECharts option ──

  const chartOption = computed<EChartsOption>(() => {
    const series: any[] = [];
    const hasMultipleUnitAxes = unitGroups.value.length > 1;

    // ── Numeric series ──
    for (const group of unitGroups.value) {
      for (const entry of group.entries) {
        const isRaw = entry.rawData.length > 0;
        const config = resolveSeriesConfig(entry);
        const vt = entry.mp.measurement_subtype?.value_type;

        const data = isRaw
          ? entry.rawData.map((rv) => [
              new Date(rv.sample_time).getTime(),
              rv.scaled_value
            ])
          : vt === 'accumulative'
            ? entry.hourlyData.map((h) => [
                hourToTimestamp(h.date, h.hour),
                h.delta ?? 0
              ])
            : entry.hourlyData.map((h) => [
                hourToTimestamp(h.date, h.hour),
                h.avg_value
              ]);

        series.push({
          name: entry.mp.name,
          type: config.type,
          step: config.step || false,
          areaStyle: config.areaStyle,
          yAxisIndex: group.yAxisIndex,
          data,
          itemStyle: { color: entryColor(entry) },
          lineStyle: { width: 2 },
          symbol: 'none',
          smooth: config.type === 'line' && !config.step,
          barMaxWidth: 30
        });
      }
    }

    // ── Step status series ──
    // areaStyle.origin = yOffset fills ONLY between the offset baseline and the line
    for (const entry of stepEntries.value) {
      const yOff = statusOffset(entry);
      const isRaw = entry.rawData.length > 0;
      const color = entryColor(entry);

      const data = isRaw
        ? buildRawStepData(entry.rawData, yOff)
        : buildHourlyStepData(entry.hourlyData, yOff);

      series.push({
        name: entry.mp.name,
        type: 'line',
        step: 'start',
        yAxisIndex: statusYAxisIndex.value,
        data,
        itemStyle: { color },
        lineStyle: { width: 2, color },
        areaStyle: {
          color,
          opacity: 0.25,
          origin: yOff
        },
        symbol: 'none'
      });
    }

    // ── RangeBar status series ──
    for (const entry of rangeBarEntries.value) {
      const yOff = statusOffset(entry);
      const isRaw = entry.rawData.length > 0;
      const color = entryColor(entry);

      const data = isRaw
        ? buildRawRangeBarData(entry.rawData, yOff)
        : buildHourlyRangeBarData(entry.hourlyData, yOff);

      series.push({
        name: entry.mp.name,
        type: 'custom',
        yAxisIndex: statusYAxisIndex.value,
        data,
        renderItem: (_params: any, api: any) => {
          const xStartVal = api.value(0);
          const xEndVal = api.value(1);
          const offset = api.value(2) as number;
          const isOn = api.value(3) as number;

          const topLeft = api.coord([xStartVal, offset + STATUS_BAND_HEIGHT]);
          const bottomRight = api.coord([xEndVal, offset]);

          return {
            type: 'rect',
            shape: {
              x: topLeft[0],
              y: topLeft[1],
              width: Math.max(bottomRight[0] - topLeft[0], 1),
              height: Math.abs(bottomRight[1] - topLeft[1])
            },
            style: api.style({
              fill: isOn ? color : '#e5e7eb',
              opacity: isOn ? 0.7 : 0.25
            })
          };
        },
        encode: {
          x: [0, 1],
          y: 2
        },
        tooltip: {
          formatter: (params: any) => {
            if (!params.data)
              return '';

            const [startTs, endTs, , isOn] = params.data;
            const startStr = new Date(startTs).toLocaleString();
            const endStr = new Date(endTs).toLocaleString();
            const state = isOn ? 'ON' : 'OFF';
            // console.log('RangeBar tooltip params:', params);
            // const state = getDisplayValue(isOn, params.mp.effective_value_format, {
            //   enumValues: params.mp.enum_values
            // });
            const durationMs = endTs - startTs;
            const durationMin = Math.round(durationMs / 60000);
            const durationStr = durationMin >= 60
              ? `${Math.floor(durationMin / 60)}h ${durationMin % 60}m`
              : `${durationMin}m`;
            return `
              <strong>${params.seriesName}</strong><br/>
              ${state} for ${durationStr}<br/>
              <span style="color:#999">${startStr} → ${endStr}</span>
            `;
          }
        }
      });
    }

    // ── Y-axes ──
    const yAxis: any[] = [];

    for (let i = 0; i < unitGroups.value.length; i++) {
      const group = unitGroups.value[i];
      yAxis.push({
        type: 'value',
        name: group.unit || undefined,
        position: i === 0 ? 'left' : 'right',
        offset: i > 1 ? (i - 1) * 60 : 0,
        axisLabel: {
          formatter: (val: number) => {
            if (val === null || val === undefined)
              return '';

            return group.unit
              ? `${Number(val.toFixed(2))} ${group.unit}`
              : String(Number(val.toFixed(2)));
          },
          fontSize: 11
        },
        nameTextStyle: { fontSize: 12 },
        splitLine: { show: i === 0 },
        axisLine: { show: hasMultipleUnitAxes },
        axisTick: { show: hasMultipleUnitAxes }
      });
    }

    // Status y-axis: shows MP name labels at each band's midpoint
    if (statusEntries.value.length > 0) {
      const tickValues: number[] = [];
      const labelMap = new Map<number, string>();

      for (const entry of statusEntries.value) {
        const yOff = statusOffset(entry);
        const mid = yOff + STATUS_BAND_HEIGHT / 2;
        tickValues.push(mid);
        labelMap.set(mid, entry.mp.name);
      }

      yAxis.push({
        type: 'value',
        position: 'right',
        offset: hasMultipleUnitAxes ? 60 : 0,
        min: statusYRange.value.min,
        max: statusYRange.value.max,
        splitLine: { show: false },
        axisLine: { show: false },
        axisTick: { show: false },
        axisLabel: {
          fontSize: 11,
          customValues: tickValues,
          formatter: (val: number) => {
            // Find the closest label
            for (const [tickVal, label] of labelMap) {
              if (Math.abs(val - tickVal) < 0.01)
                return label;
            }
            return '';
          }
        }
      });
    }

    if (yAxis.length === 0)
      yAxis.push({ type: 'value' });

    // ── Baseline mark lines for status bands ──
    // Dashed lines at ON and OFF levels help visually distinguish the two states
    const statusMarkLines: any[] = [];
    for (const entry of statusEntries.value) {
      const yOff = statusOffset(entry);
      const color = entryColor(entry);
      // TO DO
      statusMarkLines.push(
        {
          yAxis: yOff,
          lineStyle: { color, type: 'dashed', width: 1, opacity: 0.2 },
          label: {
            show: true,
            position: 'insideStartTop',
            formatter: 'OFF',
            fontSize: 9,
            color: '#9ca3af'
          }
        },
        {
          yAxis: yOff + STATUS_BAND_HEIGHT,
          lineStyle: { color, type: 'dashed', width: 1, opacity: 0.2 },
          label: {
            show: true,
            position: 'insideStartTop',
            formatter: 'ON',
            fontSize: 9,
            color: '#6b7280'
          }
        }
      );
    }

    // Attach markLines to the first status series
    if (statusMarkLines.length > 0) {
      const firstStatusIdx = series.findIndex(
        (s: any) => s.yAxisIndex === statusYAxisIndex.value
      );
      if (firstStatusIdx >= 0) {
        series[firstStatusIdx].markLine = {
          silent: true,
          symbol: 'none',
          data: statusMarkLines
        };
      }
    }

    return {
      animation: true,
      grid: {
        left: 60,
        right: statusEntries.value.length > 0
          ? (hasMultipleUnitAxes ? 160 : 100)
          : (hasMultipleUnitAxes ? 80 : 20),
        top: 50,
        bottom: 50,
        containLabel: false
      },
      tooltip: {
        trigger: 'axis',
        axisPointer: { type: 'cross' },
        formatter: (params: any) => {
          if (!Array.isArray(params))
            return '';

          const normalParams = params.filter((p: any) => p.seriesType !== 'custom');
          if (normalParams.length === 0)
            return '';

          const time = new Date(normalParams[0].data[0]).toLocaleString();
          let html = `<strong>${time}</strong>`;

          for (const p of normalParams) {
            const stepEntry = stepEntries.value.find((e) => e.mp.name === p.seriesName);

            if (stepEntry) {
              const yOff = statusOffset(stepEntry);
              const rawLevel = (p.data[1] as number) - yOff;
              const state = rawLevel >= 0.5 ? 'ON' : 'OFF';
              // console.log('RangeBar tooltip params:', p);
              // const state = getDisplayValue(rawLevel >= 0.5 ? 1 : 0, p.mp.effective_value_format, {
              //   enumValues: p.mp.enum_values
              // });
              html += `<br/>${p.marker} ${p.seriesName}: <strong>${state}</strong>`;
            } else {
              const val = p.data[1];
              if (val !== null && val !== undefined) {
                const unit = findUnitForEntry(p.seriesName);
                const formatted = unit
                  ? `${Number(Number(val).toFixed(2))} ${unit}`
                  : String(Number(Number(val).toFixed(2)));
                html += `<br/>${p.marker} ${p.seriesName}: <strong>${formatted}</strong>`;
              }
            }
          }
          return html;
        }
      },
      legend: {
        top: 0,
        type: 'scroll',
        textStyle: { fontSize: 12 }
      },
      xAxis: {
        type: 'time',
        axisLabel: { fontSize: 11 }
      },
      yAxis,
      series,
      dataZoom: [
        {
          type: 'inside',
          xAxisIndex: 0,
          filterMode: 'none'
        }
      ],
      toolbox: {
        feature: {
          dataZoom: { yAxisIndex: false },
          restore: {},
          saveAsImage: {}
        }
      }
    };
  });

  // ── Step data builders ──

  function buildRawStepData(rawData: RawValue[], yOffset: number): number[][] {
    if (rawData.length === 0)
      return [];

    return rawData.map((rv) => [
      new Date(rv.sample_time).getTime(),
      (rv.scaled_value > 0 ? STATUS_BAND_HEIGHT : 0) + yOffset
    ]);
  }

  function buildHourlyStepData(hourlyData: HourlyAggregation[], yOffset: number): number[][] {
    if (hourlyData.length === 0)
      return [];

    return hourlyData.map((h) => {
      const onRatio =
        h.time_on_seconds !== null && h.time_off_seconds !== null
          ? h.time_on_seconds / (h.time_on_seconds + h.time_off_seconds)
          : 0;
      return [
        hourToTimestamp(h.date, h.hour),
        (onRatio >= 0.5 ? STATUS_BAND_HEIGHT : 0) + yOffset
      ];
    });
  }

  // ── RangeBar data builders ──
  // Consecutive same-state points are merged into single rectangles

  function buildRawRangeBarData(rawData: RawValue[], yOffset: number): number[][] {
    if (rawData.length === 0)
      return [];

    const segments: number[][] = [];
    let segStart = new Date(rawData[0].sample_time).getTime();
    let segOn = rawData[0].scaled_value > 0 ? 1 : 0;

    for (let i = 1; i < rawData.length; i++) {
      const ts = new Date(rawData[i].sample_time).getTime();
      const isOn = rawData[i].scaled_value > 0 ? 1 : 0;

      if (isOn !== segOn) {
        segments.push([segStart, ts, yOffset, segOn]);
        segStart = ts;
        segOn = isOn;
      }
    }

    // Close the last segment
    const lastTs = new Date(rawData[rawData.length - 1].sample_time).getTime();
    if (lastTs > segStart)
      segments.push([segStart, lastTs, yOffset, segOn]);

    return segments;
  }

  function buildHourlyRangeBarData(hourlyData: HourlyAggregation[], yOffset: number): number[][] {
    if (hourlyData.length === 0)
      return [];

    return hourlyData.map((h) => {
      const start = hourToTimestamp(h.date, h.hour);
      const end = start + 3600000;
      const onRatio =
        h.time_on_seconds !== null && h.time_off_seconds !== null
          ? h.time_on_seconds / (h.time_on_seconds + h.time_off_seconds)
          : 0;
      return [start, end, yOffset, onRatio >= 0.5 ? 1 : 0];
    });
  }

  function findUnitForEntry(seriesName: string): string {
    for (const group of unitGroups.value) {
      for (const entry of group.entries) {
        if (entry.mp.name === seriesName)
        return group.unit;
      }
    }
    return '';
  }
</script>

<style scoped>
  .empty-state {
    color: #9ca3af;
  }
</style>
