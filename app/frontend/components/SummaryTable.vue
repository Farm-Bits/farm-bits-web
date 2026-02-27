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
            <CTableRow v-for="row in instantaneousRows" :key="row.id">
              <CTableDataCell>
                <span
                  v-if="row.color"
                  class="color-dot me-2"
                  :style="{ backgroundColor: row.color }" />
                {{ row.name }}
              </CTableDataCell>
              <CTableDataCell class="text-end">{{ formatNum(row.summary.min_value) }}</CTableDataCell>
              <CTableDataCell class="text-end">{{ formatNum(row.summary.max_value) }}</CTableDataCell>
              <CTableDataCell class="text-end">{{ formatNum(row.summary.avg_value) }}</CTableDataCell>
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
            <CTableRow v-for="row in accumulativeRows" :key="row.id">
              <CTableDataCell>
                <span
                  v-if="row.color"
                  class="color-dot me-2"
                  :style="{ backgroundColor: row.color }" />
                {{ row.name }}
              </CTableDataCell>
              <CTableDataCell class="text-end">{{ formatNum(row.summary.start_value) }}</CTableDataCell>
              <CTableDataCell class="text-end">{{ formatNum(row.summary.end_value) }}</CTableDataCell>
              <CTableDataCell class="text-end fw-semibold">{{ formatNum(row.summary.total_delta) }}</CTableDataCell>
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
            <CTableRow v-for="row in statusRows" :key="row.id">
              <CTableDataCell>
                <span
                  v-if="row.color"
                  class="color-dot me-2"
                  :style="{ backgroundColor: row.color }" />
                {{ row.name }}
              </CTableDataCell>
              <CTableDataCell class="text-end">{{ formatDuration(row.summary.total_time_on_seconds) }}</CTableDataCell>
              <CTableDataCell class="text-end">{{ formatDuration(row.summary.total_time_off_seconds) }}</CTableDataCell>
              <CTableDataCell class="text-end">
                <template v-if="row.summary.on_percentage !== undefined && row.summary.on_percentage !== null">
                  {{ row.summary.on_percentage }}%
                </template>
                <template v-else>—</template>
              </CTableDataCell>
              <CTableDataCell class="text-end">{{ row.summary.total_transitions ?? '—' }}</CTableDataCell>
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
  import type { ValueType } from '@/types/measurementPoint';

  type DataSummary = {
    // Accumulative
    start_value?: number | null;
    end_value?: number | null;
    total_delta?: number | null;

    // Instantaneous
    min_value?: number | null;
    max_value?: number | null;
    avg_value?: number | null;

    // Status
    total_time_on_seconds?: number | null;
    total_time_off_seconds?: number | null;
    on_percentage?: number | null;
    total_transitions?: number | null;
  };

  export type RowDefinition = {
    id: number;
    name: string;
    value_type: ValueType;
    unit: string | null;
    color: string | null;
    summary: DataSummary;
  };

  const { rows } = defineProps<{
    rows: RowDefinition[];
  }>();

  // ── Build rows per value type ──

  function buildRows(valueType: ValueType) {
    return rows.filter((row) => row.value_type === valueType);
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
