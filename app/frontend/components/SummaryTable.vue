<template>
  <div class="summary-table-wrapper">
    <template v-if="hasSummaryData">
      <!-- Instantaneous sub-table -->
      <div v-if="instantaneousRows.length > 0" class="mb-3">
        <h6 v-if="hasMultipleValueTypes" class="sub-table-title text-body-secondary mb-2">
          <CIcon name="cil-chart-line" size="sm" class="me-1" />
          Readings
        </h6>
        <CTable hover class="summary-table mb-0">
          <CTableHead>
            <CTableRow>
              <CTableHeaderCell>Name</CTableHeaderCell>
              <CTableHeaderCell class="text-end">Min</CTableHeaderCell>
              <CTableHeaderCell class="text-end">Max</CTableHeaderCell>
              <CTableHeaderCell class="text-end">Avg</CTableHeaderCell>
              <CTableHeaderCell>Unit</CTableHeaderCell>
            </CTableRow>
          </CTableHead>
          <CTableBody>
            <CTableRow v-for="row in instantaneousRows" :key="row.measurementPointId">
              <CTableDataCell>
                <span
                  v-if="row.color"
                  class="color-dot me-2"
                  :style="{ backgroundColor: row.color }" />
                {{ row.name }}
              </CTableDataCell>
              <CTableDataCell class="text-end">{{ formatNum((row.summary as any).min_value) }}</CTableDataCell>
              <CTableDataCell class="text-end">{{ formatNum((row.summary as any).max_value) }}</CTableDataCell>
              <CTableDataCell class="text-end">{{ formatNum((row.summary as any).avg_value) }}</CTableDataCell>
              <CTableDataCell>{{ row.unit }}</CTableDataCell>
            </CTableRow>
          </CTableBody>
        </CTable>
      </div>

      <!-- Accumulative sub-table -->
      <div v-if="accumulativeRows.length > 0" class="mb-3">
        <h6 v-if="hasMultipleValueTypes" class="sub-table-title text-body-secondary mb-2">
          <CIcon name="cil-bar-chart" size="sm" class="me-1" />
          Consumption
        </h6>
        <CTable hover class="summary-table mb-0">
          <CTableHead>
            <CTableRow>
              <CTableHeaderCell>Name</CTableHeaderCell>
              <CTableHeaderCell class="text-end">Start</CTableHeaderCell>
              <CTableHeaderCell class="text-end">End</CTableHeaderCell>
              <CTableHeaderCell class="text-end">Total</CTableHeaderCell>
              <CTableHeaderCell>Unit</CTableHeaderCell>
            </CTableRow>
          </CTableHead>
          <CTableBody>
            <CTableRow v-for="row in accumulativeRows" :key="row.measurementPointId">
              <CTableDataCell>
                <span
                  v-if="row.color"
                  class="color-dot me-2"
                  :style="{ backgroundColor: row.color }" />
                {{ row.name }}
              </CTableDataCell>
              <CTableDataCell class="text-end">{{ formatNum((row.summary as any).start_value) }}</CTableDataCell>
              <CTableDataCell class="text-end">{{ formatNum((row.summary as any).end_value) }}</CTableDataCell>
              <CTableDataCell class="text-end fw-semibold">{{ formatNum((row.summary as any).total_delta) }}</CTableDataCell>
              <CTableDataCell>{{ row.unit }}</CTableDataCell>
            </CTableRow>
          </CTableBody>
        </CTable>
      </div>

      <!-- Status sub-table -->
      <div v-if="statusRows.length > 0">
        <h6 v-if="hasMultipleValueTypes" class="sub-table-title text-body-secondary mb-2">
          <CIcon name="cil-toggle-on" size="sm" class="me-1" />
          Switches
        </h6>
        <CTable hover class="summary-table mb-0">
          <CTableHead>
            <CTableRow>
              <CTableHeaderCell>Name</CTableHeaderCell>
              <CTableHeaderCell class="text-end">On Time</CTableHeaderCell>
              <CTableHeaderCell class="text-end">Off Time</CTableHeaderCell>
              <CTableHeaderCell class="text-end">On %</CTableHeaderCell>
              <CTableHeaderCell class="text-end">Transitions</CTableHeaderCell>
            </CTableRow>
          </CTableHead>
          <CTableBody>
            <CTableRow v-for="row in statusRows" :key="row.measurementPointId">
              <CTableDataCell>
                <span
                  v-if="row.color"
                  class="color-dot me-2"
                  :style="{ backgroundColor: row.color }" />
                {{ row.name }}
              </CTableDataCell>
              <CTableDataCell class="text-end">{{ formatDuration((row.summary as any).total_time_on_seconds) }}</CTableDataCell>
              <CTableDataCell class="text-end">{{ formatDuration((row.summary as any).total_time_off_seconds) }}</CTableDataCell>
              <CTableDataCell class="text-end">
                <template v-if="(row.summary as any).on_percentage !== null">
                  {{ (row.summary as any).on_percentage }}%
                </template>
                <template v-else>—</template>
              </CTableDataCell>
              <CTableDataCell class="text-end">{{ (row.summary as any).total_transitions ?? '—' }}</CTableDataCell>
            </CTableRow>
          </CTableBody>
        </CTable>
      </div>
    </template>

    <div v-else class="text-center py-4 text-body-secondary">
      No summary data available
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import type { AnalyticsSummary } from '@/types/analytics';

  type SummaryTableMeasurementPoint = {
    id: number;
    name: string;
    effective_unit: string | null;
    effective_color: string | null;
  };

  const { measurementPoints, summaryData } = defineProps<{
    measurementPoints: SummaryTableMeasurementPoint[];
    summaryData: Record<SummaryTableMeasurementPoint['id'], AnalyticsSummary>;
  }>();

  // ── Row type (summary is the AnalyticsSummary union, narrowed by filtering) ──

  type SummaryRow = {
    measurementPointId: number;
    name: string;
    unit: string;
    color: string | null;
    summary: AnalyticsSummary;
  };

  // ── Build rows per value type ──

  function buildRows(valueType: string): SummaryRow[] {
    return measurementPoints
      .filter((mp) => {
        const s = summaryData[mp.id];
        return s && s.value_type === valueType;
      })
      .map((mp) => ({
        measurementPointId: mp.id,
        name: mp.name,
        unit: mp.effective_unit ?? '',
        color: mp.effective_color ?? null,
        summary: summaryData[mp.id],
      }));
  }

  const instantaneousRows = computed(() => buildRows('instantaneous'));
  const accumulativeRows = computed(() => buildRows('accumulative'));
  const statusRows = computed(() => buildRows('status'));

  const hasSummaryData = computed(() =>
    instantaneousRows.value.length > 0 ||
    accumulativeRows.value.length > 0 ||
    statusRows.value.length > 0
  );

  const hasMultipleValueTypes = computed(() => {
    let count = 0;
    if (instantaneousRows.value.length > 0)
      count++;

    if (accumulativeRows.value.length > 0)
      count++;

    if (statusRows.value.length > 0)
      count++;

    return count > 1;
  });

  // ── Formatters ──

  function formatNum(val: number | null | undefined) {
    if (val === null || val === undefined) return '—';
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

  .sub-table-title {
    font-size: 0.8125rem;
    font-weight: 600;
  }

  .color-dot {
    display: inline-block;
    width: 10px;
    height: 10px;
    border-radius: 50%;
    vertical-align: middle;
  }
</style>
