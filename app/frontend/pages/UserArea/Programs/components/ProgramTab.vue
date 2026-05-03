
<template>
  <div>
    <!-- Meta block -->
    <div v-if="program.meta" class="mb-4">
      <div class="text-medium-emphasis small mb-2">
        {{ groupLabels[program.meta.group_name] ?? 'Program' }}
      </div>
      <CRow>
        <CCol
          v-for="rm in program.meta.registers"
          :key="rm.register_template.id"
          md="4"
          class="mb-2">
          <div class="small text-medium-emphasis mb-1">
            {{ rm.register_template.name }}
          </div>
          <ProgramCell
            :mapping="rm"
            :pending-value="pendingValueFor(rm.measurement_point)"
            :has-pending-change="cellHasPendingChange(rm.measurement_point)"
            @update:value="(v: CellValue) => setPendingChange(rm.measurement_point, v)" />
        </CCol>
      </CRow>
    </div>

    <!-- Phase table -->
    <div v-if="program.phases.length > 0">
      <div class="text-medium-emphasis small mb-2">
        {{ groupLabels[program.phases[0]?.group_name] ?? 'Phases' }}
      </div>

      <CTable bordered responsive small>
        <CTableHead>
          <CTableRow>
            <CTableHeaderCell scope="col">#</CTableHeaderCell>
            <CTableHeaderCell
              v-for="col in columnDefs"
              :key="col.register_template.id"
              scope="col">
              {{ col.register_template.name }}
            </CTableHeaderCell>
          </CTableRow>
        </CTableHead>

        <CTableBody>
          <CTableRow v-for="row in phaseRows" :key="row.phaseIndex">
            <CTableHeaderCell scope="row">{{ row.phaseIndex }}</CTableHeaderCell>
            <CTableDataCell v-for="(cell, colIdx) in row.cells" :key="colIdx">
              <template v-if="cell">
                <ProgramCell
                  :mapping="cell"
                  :pending-value="pendingValueFor(cell.measurement_point)"
                  :has-pending-change="cellHasPendingChange(cell.measurement_point)"
                  @update:value="(v: CellValue) => setPendingChange(cell.measurement_point, v)" />
              </template>
              <template v-else>—</template>
            </CTableDataCell>
          </CTableRow>
        </CTableBody>
      </CTable>
    </div>

    <!-- Save / discard controls -->
    <CAlert v-if="saveError" color="danger" dismissible @close="saveError = null">
      {{ saveError }}
    </CAlert>

    <div class="d-flex gap-2 mt-3">
      <CButton
        color="primary"
        :disabled="!hasPendingChanges || isSaving"
        @click="saveProgram">
        {{ isSaving ? 'Saving…' : `Save program ${program.index}` }}
      </CButton>
      <CButton
        color="secondary"
        variant="outline"
        :disabled="!hasPendingChanges || isSaving"
        @click="discardChanges">
        Discard changes
      </CButton>
    </div>
  </div>
</template>

<script setup lang="ts">
  import { ref, computed, reactive } from 'vue';
  import axios from 'axios';
  import ProgramCell from './ProgramCell.vue';
  import type { RegisterMapping } from '@/types/plc';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { Program } from '../types';

  type CellValue = MeasurementPoint['last_value'];

  // Per-row data shape used by the phase table. Each entry is either a
  // RegisterMapping (cell exists for this column) or null (column missing
  // for this phase, render placeholder).
  type PhaseRow = {
    phaseIndex: number;
    cells: Array<RegisterMapping | null>;
  };

  const props = defineProps<{
    program: Program;
    groupLabels: Record<string, string>;
  }>();

  // ── Column definitions ─────────────────────────────────────────────
  // The first phase's registers, sorted by position, define the columns.
  // The schema contract guarantees every phase has the same group_role
  // set, so this is a stable definition for the whole program.

  const columnDefs = computed<RegisterMapping[]>(() => {
    if (props.program.phases.length === 0)
      return [];

    return [...props.program.phases[0].registers].sort((a, b) => a.position - b.position);
  });

  // ── Phase rows (precomputed, no inline lookup repetition) ──────────

  const phaseRows = computed<PhaseRow[]>(() => {
    const cols = columnDefs.value;
    return props.program.phases.map((phase) => {
      const byRole: Record<string, RegisterMapping> = {};
      phase.registers.forEach((rm) => {
        const role = rm.register_template.group_role;
        if (role === null)
          return;

        byRole[role] = rm;
      });

      const cells = cols.map((col) => {
        const role = col.register_template.group_role;
        if (role === null)
          return null;

        return byRole[role] ?? null;
      });

      return { phaseIndex: phase.index, cells };
    });
  });

  // ── Pending change tracking ────────────────────────────────────────

  const pendingChanges = reactive<Record<number, CellValue>>({});

  const hasPendingChanges = computed(() => Object.keys(pendingChanges).length > 0);

  function pendingValueFor(mp: MeasurementPoint) {
    return pendingChanges[mp.id];
  }

  function cellHasPendingChange(mp: MeasurementPoint) {
    return mp.id in pendingChanges;
  }

  function setPendingChange(mp: MeasurementPoint, value: CellValue) {
    if (value === mp.last_value) {
      delete pendingChanges[mp.id];
      return;
    }

    pendingChanges[mp.id] = value;
  }

  function discardChanges() {
    Object.keys(pendingChanges).forEach((k) => delete pendingChanges[Number(k)]);
    saveError.value = null;
  }

  // ── Save ───────────────────────────────────────────────────────────

  const isSaving = ref(false);
  const saveError = ref<string | null>(null);

  async function saveProgram() {
    if (!hasPendingChanges.value)
      return;

    isSaving.value = true;
    saveError.value = null;

    const updates = Object.entries(pendingChanges).map(([mpId, value]) => ({
      measurement_point_id: Number(mpId),
      value: value
    }));

    try {
      const response = await axios.post('/user/measurement_points/bulk_write', {
        configuration_updates: updates
      });

      const refreshed = response.data.measurement_points as MeasurementPoint[];
      patchLocalValues(refreshed);

      Object.keys(pendingChanges).forEach((k) => delete pendingChanges[Number(k)]);
    } catch (err) {
      saveError.value = extractErrorMessage(err);
    } finally {
      isSaving.value = false;
    }
  }

  function patchLocalValues(refreshed: MeasurementPoint[]) {
    const byId: Record<number, MeasurementPoint> = {};
    refreshed.forEach((mp) => { byId[mp.id] = mp });

    const allMappings: RegisterMapping[] = [
      ...(props.program.meta?.registers ?? []),
      ...props.program.phases.flatMap((p) => p.registers)
    ];

    allMappings.forEach((rm) => {
      const updated = byId[rm.measurement_point.id];
      if (!updated)
        return;

      rm.measurement_point.last_value = updated.last_value;
      rm.measurement_point.last_value_at = updated.last_value_at;
    });
  }

  function extractErrorMessage(err: unknown) {
    if (axios.isAxiosError(err) && err.response?.data?.error)
      return err.response.data.error;

    return 'Failed to save program';
  }
</script>
