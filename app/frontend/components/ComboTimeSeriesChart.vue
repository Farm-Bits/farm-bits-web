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
  import type { ChartType, ValueType } from '@/types/measurementPoint';
  import type { RegisterTemplate } from '@/types/plc';

  export type SerieDefinition = {
    id: number;
    name: string;
    unit: string | null;
    chart_type: ChartType | null;
    color: string | null;
    value_format: RegisterTemplate['value_format'];
    enum_values?: RegisterTemplate['enum_values'];
    value_type: ValueType;
  };

  type HourlyValue = {
    date: string;
    hour: number;
    // Accumulative
    delta?: number | null;
    // Instantaneous
    avg_value?: number | null;
    // Status
    time_on_seconds?: number | null;
    time_off_seconds?: number | null;
  };

  type RawValue = {
    value: number;
    sample_time: string;
  };

  export type ChartEntry = {
    serieDefinition: SerieDefinition;
    hourlyData: HourlyValue[];
    rawData: RawValue[];
  };

  const {
    entries,
    height = 360,
  } = defineProps<{
    entries: ChartEntry[];
    height?: number;
  }>();

  const numericEntries = computed(() =>
    entries.filter((e) => {
      const vt = e.serieDefinition.value_type;
      return vt === 'instantaneous' || vt === 'accumulative';
    })
  );

  const statusEntries = computed(() =>
    entries.filter((e) => e.serieDefinition.value_type === 'status')
  );

  function isRawEntry(entry: ChartEntry) {
    return entry.rawData.length > 0;
  }

  function isHourlyEntry(entry: ChartEntry) {
    return entry.hourlyData.length > 0 && entry.rawData.length === 0;
  }

  // ── Status sub-partitions ──
  // Raw status entries keep their original chart type (step or rangeBar).
  // Hourly status entries are ALWAYS rendered as percentage bars regardless of chart_type,
  // because binary step/rangeBar loses proportional on-time information at hourly aggregation.

  const rawStepEntries = computed(() =>
    statusEntries.value.filter((e) => {
      if (!isRawEntry(e))
        return false;

      return e.serieDefinition.chart_type === 'step';
    })
  );

  const rawRangeBarEntries = computed(() =>
    statusEntries.value.filter((e) => {
      if (!isRawEntry(e))
        return false;

      return e.serieDefinition.chart_type === 'rangeBar';
    })
  );

  const hourlyStatusEntries = computed(() =>
    statusEntries.value.filter((e) => isHourlyEntry(e))
  );

  const hasData = computed(() =>
    entries.some((e) => e.hourlyData.length > 0 || e.rawData.length > 0)
  );

  // Each raw status MP gets a band of height 1 with 0.5 gap between them
  const STATUS_BAND_HEIGHT = 1;
  const STATUS_GAP = 0.5;

  const chartHeight = computed(() => {
    const rawStatusCount = statusEntries.value.filter((e) => isRawEntry(e)).length;
    const statusExtra = rawStatusCount * 50;
    // Hourly status bars share the percentage axis, so they need less extra height
    const hourlyExtra = hourlyStatusEntries.value.length > 0 ? 30 : 0;
    return height + statusExtra + hourlyExtra;
  });

  const PALETTE = [
    '#059669', '#2563eb', '#d97706', '#dc2626', '#7c3aed',
    '#db2777', '#0891b2', '#65a30d', '#ea580c', '#4f46e5',
  ];

  const colorMap = computed(() => {
    const map = new Map<number, string>();
    let idx = 0;
    for (const entry of [...numericEntries.value, ...statusEntries.value]) {
      map.set(entry.serieDefinition.id, entry.serieDefinition.color ?? PALETTE[idx % PALETTE.length]);
      idx++;
    }
    return map;
  });

  function entryColor(entry: ChartEntry) {
    return colorMap.value.get(entry.serieDefinition.id) ?? PALETTE[0];
  }

  function statusLabel(entry: ChartEntry, rawValue: number) {
    return getDisplayValue(
      rawValue,
      entry.serieDefinition.value_format,
      {
        unit: entry.serieDefinition.unit,
        enumValues: entry.serieDefinition.enum_values
      }
    );
  }

  function statusOnLabel(entry: ChartEntry) {
    return statusLabel(entry, 1);
  }

  function statusOffLabel(entry: ChartEntry) {
    return statusLabel(entry, 0);
  }

  function hourToTimestamp(date: string, hour: number) {
    return new Date(`${date}T${String(hour).padStart(2, '0')}:00:00`).getTime();
  }

  function rawStatusOffset(entry: ChartEntry) {
    const rawStatuses = statusEntries.value.filter((e) => isRawEntry(e));
    const idx = rawStatuses.findIndex((e) => e.serieDefinition.id === entry.serieDefinition.id);
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
      const unit = entry.serieDefinition.unit ?? '';
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

  // Y-axis indices layout:
  // [0..N-1] = numeric unit groups
  // [N]      = raw status band axis (step/rangeBar) — only if raw status entries exist
  // [N+1]    = hourly status percentage axis (0-100%) — only if hourly status entries exist

  const hasRawStatus = computed(() =>
    rawStepEntries.value.length > 0 || rawRangeBarEntries.value.length > 0
  );

  const hasHourlyStatus = computed(() =>
    hourlyStatusEntries.value.length > 0
  );

  const rawStatusYAxisIndex = computed(() => unitGroups.value.length);

  const hourlyStatusYAxisIndex = computed(() =>
    unitGroups.value.length + (hasRawStatus.value ? 1 : 0)
  );

  const rawStatusYRange = computed(() => {
    const rawStatuses = statusEntries.value.filter((e) => isRawEntry(e));
    const count = rawStatuses.length;
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
    const chartType = entry.serieDefinition.chart_type as ChartType | null;
    const vt = entry.serieDefinition.value_type;
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
        const vt = entry.serieDefinition.value_type;

        const data = isRaw
          ? entry.rawData.map((rv) => [
              new Date(rv.sample_time).getTime(),
              rv.value
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
          name: entry.serieDefinition.name,
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

    // ── Raw Step status series ──
    for (const entry of rawStepEntries.value) {
      const yOff = rawStatusOffset(entry);
      const color = entryColor(entry);
      const data = buildRawStepData(entry.rawData, yOff);

      series.push({
        name: entry.serieDefinition.name,
        type: 'line',
        step: 'start',
        yAxisIndex: rawStatusYAxisIndex.value,
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

    // ── Raw RangeBar status series ──
    for (const entry of rawRangeBarEntries.value) {
      const yOff = rawStatusOffset(entry);
      const color = entryColor(entry);
      const data = buildRawRangeBarData(entry.rawData, yOff);

      series.push({
        name: entry.serieDefinition.name,
        type: 'custom',
        yAxisIndex: rawStatusYAxisIndex.value,
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
            const state = statusLabel(entry, isOn ? 1 : 0);
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

    // ── Hourly status: percentage bar series ──
    // Instead of binary ON/OFF (which loses granularity at hourly aggregation),
    // show the actual on-time percentage as a bar for each hour.
    for (const entry of hourlyStatusEntries.value) {
      const color = entryColor(entry);
      const onLbl = statusOnLabel(entry);
      const offLbl = statusOffLabel(entry);

      const data = entry.hourlyData.map((h) => {
        const onPct = computeOnPercentage(h);
        return [hourToTimestamp(h.date, h.hour), onPct];
      });

      series.push({
        name: entry.serieDefinition.name,
        type: 'bar',
        yAxisIndex: hourlyStatusYAxisIndex.value,
        data,
        itemStyle: {
          color: (params: any) => {
            const pct = params.data[1] as number;
            // Visual intensity scales with on-time percentage
            if (pct === 0)
              return '#e5e7eb';

            if (pct < 25)
              return adjustOpacity(color, 0.35);

            if (pct < 50)
              return adjustOpacity(color, 0.55);

            if (pct < 75)
              return adjustOpacity(color, 0.75);
            return color;
          }
        },
        barMaxWidth: 30,
        tooltip: {
          valueFormatter: (pct: number) => {
            return `${onLbl}: ${Math.round(pct)}% · ${offLbl}: ${Math.round(100 - pct)}%`;
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

    // Raw status y-axis: shows MP name labels at each band's midpoint
    if (hasRawStatus.value) {
      const rawStatuses = statusEntries.value.filter((e) => isRawEntry(e));
      const tickValues: number[] = [];
      const labelMap = new Map<number, string>();

      for (const entry of rawStatuses) {
        const yOff = rawStatusOffset(entry);
        const mid = yOff + STATUS_BAND_HEIGHT / 2;
        tickValues.push(mid);
        labelMap.set(mid, entry.serieDefinition.name);
      }

      yAxis.push({
        type: 'value',
        position: 'right',
        offset: hasMultipleUnitAxes ? 60 : 0,
        min: rawStatusYRange.value.min,
        max: rawStatusYRange.value.max,
        splitLine: { show: false },
        axisLine: { show: false },
        axisTick: { show: false },
        axisLabel: {
          fontSize: 11,
          customValues: tickValues,
          formatter: (val: number) => {
            for (const [tickVal, label] of labelMap) {
              if (Math.abs(val - tickVal) < 0.01)
                return label;
            }
            return '';
          }
        }
      });
    }

    // Hourly status percentage y-axis (0–100%)
    if (hasHourlyStatus.value) {
      const rightOffset = hasMultipleUnitAxes
        ? (hasRawStatus.value ? 120 : 60)
        : (hasRawStatus.value ? 60 : 0);

      yAxis.push({
        type: 'value',
        name: 'Status %',
        position: 'right',
        offset: rightOffset,
        min: 0,
        max: 100,
        splitLine: { show: false },
        axisLabel: {
          formatter: '{value}%',
          fontSize: 11
        },
        nameTextStyle: { fontSize: 11 },
        axisLine: { show: true },
        axisTick: { show: true }
      });
    }

    if (yAxis.length === 0)
      yAxis.push({ type: 'value' });

    // ── Baseline mark lines for raw status bands ──
    const statusMarkLines: any[] = [];
    const rawStatuses = statusEntries.value.filter((e) => isRawEntry(e));
    for (const entry of rawStatuses) {
      const yOff = rawStatusOffset(entry);
      const color = entryColor(entry);
      const onLbl = statusOnLabel(entry);
      const offLbl = statusOffLabel(entry);

      statusMarkLines.push(
        {
          yAxis: yOff,
          lineStyle: { color, type: 'dashed', width: 1, opacity: 0.2 },
          label: {
            show: true,
            position: 'insideStartTop',
            formatter: offLbl,
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
            formatter: onLbl,
            fontSize: 9,
            color: '#6b7280'
          }
        }
      );
    }

    // Attach markLines to the first raw status series
    if (statusMarkLines.length > 0) {
      const firstStatusIdx = series.findIndex(
        (s: any) => s.yAxisIndex === rawStatusYAxisIndex.value
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
        right: computeGridRight(hasMultipleUnitAxes),
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
            // Raw step status entry
            const stepEntry = rawStepEntries.value.find((e) => e.serieDefinition.name === p.seriesName);
            if (stepEntry) {
              const yOff = rawStatusOffset(stepEntry);
              const rawLevel = (p.data[1] as number) - yOff;
              const state = statusLabel(stepEntry, rawLevel >= 0.5 ? 1 : 0);
              html += `<br/>${p.marker} ${p.seriesName}: <strong>${state}</strong>`;
              continue;
            }

            // Hourly status percentage entry
            const hourlyEntry = hourlyStatusEntries.value.find((e) => e.serieDefinition.name === p.seriesName);
            if (hourlyEntry) {
              const pct = p.data[1] as number;
              const onLbl = statusOnLabel(hourlyEntry);
              const offLbl = statusOffLabel(hourlyEntry);
              html += `<br/>${p.marker} ${p.seriesName}: <strong>${onLbl} ${Math.round(pct)}%</strong> · ${offLbl} ${Math.round(100 - pct)}%`;
              continue;
            }

            // Numeric entry
            const val = p.data[1];
            if (val !== null && val !== undefined) {
              const unit = findUnitForEntry(p.seriesName);
              const formatted = unit
                ? `${Number(Number(val).toFixed(2))} ${unit}`
                : String(Number(Number(val).toFixed(2)));
              html += `<br/>${p.marker} ${p.seriesName}: <strong>${formatted}</strong>`;
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
      dataZoom: [],
      toolbox: {
        feature: {
          dataZoom: { yAxisIndex: false },
          restore: {},
          saveAsImage: {}
        }
      }
    };
  });

  // ── Helper: compute right grid margin ──

  function computeGridRight(hasMultipleUnitAxes: boolean) {
    const axes = [
      hasMultipleUnitAxes,
      hasRawStatus.value,
      hasHourlyStatus.value,
    ].filter(Boolean).length;

    if (axes === 0)
      return 20;

    if (axes === 1)
      return 100;

    if (axes === 2)
      return 160;

    return 220;
  }

  // ── Helper: compute on-time percentage from hourly aggregation ──

  function computeOnPercentage(h: HourlyValue) {
    if (h.time_on_seconds === undefined || h.time_on_seconds === null || h.time_off_seconds === undefined || h.time_off_seconds === null)
      return 0;

    const total = h.time_on_seconds + h.time_off_seconds;
    if (total === 0)
      return 0;

    return Math.round((h.time_on_seconds / total) * 100);
  }

  // ── Helper: create rgba from hex + opacity ──

  function adjustOpacity(hexColor: string, opacity: number) {
    const r = parseInt(hexColor.slice(1, 3), 16);
    const g = parseInt(hexColor.slice(3, 5), 16);
    const b = parseInt(hexColor.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${opacity})`;
  }

  // ── Raw Step data builder ──

  function buildRawStepData(rawData: RawValue[], yOffset: number) {
    if (rawData.length === 0)
      return [];

    return rawData.map((rv) => [
      new Date(rv.sample_time).getTime(),
      (rv.value > 0 ? STATUS_BAND_HEIGHT : 0) + yOffset
    ]);
  }

  // ── Raw RangeBar data builder ──

  function buildRawRangeBarData(rawData: RawValue[], yOffset: number) {
    if (rawData.length === 0)
      return [];

    const segments: number[][] = [];
    let segStart = new Date(rawData[0].sample_time).getTime();
    let segOn = rawData[0].value > 0 ? 1 : 0;

    for (let i = 1; i < rawData.length; i++) {
      const ts = new Date(rawData[i].sample_time).getTime();
      const isOn = rawData[i].value > 0 ? 1 : 0;

      if (isOn !== segOn) {
        segments.push([segStart, ts, yOffset, segOn]);
        segStart = ts;
        segOn = isOn;
      }
    }

    const lastTs = new Date(rawData[rawData.length - 1].sample_time).getTime();
    if (lastTs > segStart)
      segments.push([segStart, lastTs, yOffset, segOn]);

    return segments;
  }

  function findUnitForEntry(seriesName: string) {
    for (const group of unitGroups.value) {
      for (const entry of group.entries) {
        if (entry.serieDefinition.name === seriesName)
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
