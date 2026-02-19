<template>
  <div class="summary-table-wrapper">
    <CTable v-if="rows.length > 0" hover class="summary-table mb-0">
      <CTableHead>
        <CTableRow>
          <CTableHeaderCell>Name</CTableHeaderCell>
          <template v-if="valueType === 'instantaneous'">
            <CTableHeaderCell class="text-end">Min</CTableHeaderCell>
            <CTableHeaderCell class="text-end">Max</CTableHeaderCell>
            <CTableHeaderCell class="text-end">Avg</CTableHeaderCell>
            <CTableHeaderCell>Unit</CTableHeaderCell>
          </template>
          <template v-else-if="valueType === 'accumulative'">
            <CTableHeaderCell class="text-end">Start</CTableHeaderCell>
            <CTableHeaderCell class="text-end">End</CTableHeaderCell>
            <CTableHeaderCell class="text-end">Total Consumption</CTableHeaderCell>
            <CTableHeaderCell>Unit</CTableHeaderCell>
          </template>
          <template v-else>
            <CTableHeaderCell class="text-end">On Time</CTableHeaderCell>
            <CTableHeaderCell class="text-end">Off Time</CTableHeaderCell>
            <CTableHeaderCell class="text-end">On %</CTableHeaderCell>
            <CTableHeaderCell class="text-end">Transitions</CTableHeaderCell>
          </template>
        </CTableRow>
      </CTableHead>
      <CTableBody>
        <CTableRow v-for="row in rows" :key="row.measurementPointId">
          <CTableDataCell>{{ row.name }}</CTableDataCell>
          <template v-if="valueType === 'instantaneous' && row.summary.value_type === 'instantaneous'">
            <CTableDataCell class="text-end">{{ formatNum(row.summary.min_value) }}</CTableDataCell>
            <CTableDataCell class="text-end">{{ formatNum(row.summary.max_value) }}</CTableDataCell>
            <CTableDataCell class="text-end">{{ formatNum(row.summary.avg_value) }}</CTableDataCell>
            <CTableDataCell>{{ row.unit }}</CTableDataCell>
          </template>
          <template v-else-if="valueType === 'accumulative' && row.summary.value_type === 'accumulative'">
            <CTableDataCell class="text-end">{{ formatNum(row.summary.start_value) }}</CTableDataCell>
            <CTableDataCell class="text-end">{{ formatNum(row.summary.end_value) }}</CTableDataCell>
            <CTableDataCell class="text-end font-weight-bold">{{ formatNum(row.summary.total_delta) }}</CTableDataCell>
            <CTableDataCell>{{ row.unit }}</CTableDataCell>
          </template>
          <template v-else-if="valueType === 'status' && row.summary.value_type === 'status'">
            <CTableDataCell class="text-end">{{ formatDuration(row.summary.total_time_on_seconds) }}</CTableDataCell>
            <CTableDataCell class="text-end">{{ formatDuration(row.summary.total_time_off_seconds) }}</CTableDataCell>
            <CTableDataCell class="text-end">
              <template v-if="row.summary.on_percentage !== null">
                {{ row.summary.on_percentage }}%
              </template>
              <template v-else>—</template>
            </CTableDataCell>
            <CTableDataCell class="text-end">{{ row.summary.total_transitions ?? '—' }}</CTableDataCell>
          </template>
        </CTableRow>
      </CTableBody>
    </CTable>
    <div v-else class="text-center py-4 text-body-secondary">
      No summary data available
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import type { MeasurementPoint, ValueType } from '@/types/measurementPoint';
  import type { AnalyticsSummary } from '@/types/analytics';

  const { measurementPoints, summaryData, valueType } = defineProps<{
    measurementPoints: MeasurementPoint[];
    summaryData: Record<MeasurementPoint['id'], AnalyticsSummary>;
    valueType: ValueType;
  }>();

  const rows = computed<{
    measurementPointId: MeasurementPoint['id'];
    name: string;
    unit: string;
    summary: AnalyticsSummary;
  }[]>(() => {
    return measurementPoints
      .filter((mp) => summaryData[mp.id])
      .map((mp) => ({
        measurementPointId: mp.id,
        name: mp.name,
        unit: mp.effective_unit ?? '',
        summary: summaryData[mp.id],
      }));
  });

  function formatNum(val: number | null | undefined) {
    if (val === null || val === undefined)
      return '—';

    return Number(val.toFixed(2)).toLocaleString();
  }

  function formatDuration(seconds: number | null | undefined) {
    if (seconds === null || seconds === undefined)
      return '—';

    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    if (h > 0)
      return `${h}h ${m}m`;

    return `${m}m`;
  }
</script>

<style scoped>
  .summary-table {
    font-size: 0.875rem;
  }

  .summary-table :deep(th) {
    font-weight: 600;
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.025em;
    color: #6b7280;
    border-bottom: 2px solid #e5e7eb;
  }

  .summary-table :deep(td) {
    vertical-align: middle;
    border-bottom: 1px solid #f3f4f6;
  }

  .summary-table :deep(tr:hover) {
    background-color: #f9fafb;
  }
</style>
