<template>
  <CContainer fluid class="py-3">
    <!-- Per-program meta (e.g. humidity mode) -->
    <div v-if="metaRegisters.length > 0" class="mb-4">
      <CRow class="g-3">
        <CCol v-for="rm in metaRegisters" :key="rm.register_template.id" md="4">
          <div class="small text-medium-emphasis mb-1 d-flex align-items-center gap-1">
            {{ rm.register_template.name }}
            <CTooltip v-if="rm.register_template.description" :content="rm.register_template.description">
              <template #toggler="{ on }">
                <CIcon v-on="on" icon="cilInfo" size="sm" class="text-muted" />
              </template>
            </CTooltip>
          </div>
          <ProgramCell
            :mapping="rm"
            :pending-value="pendingValueFor(rm.measurement_point)"
            :has-pending-change="hasPendingChange(rm.measurement_point)"
            @update:value="(value) => setPending(rm.measurement_point, value)" />
        </CCol>
      </CRow>
    </div>

    <!-- Phase grid: rows are phases, columns are the per-phase fields -->
    <div v-if="program.phases.length > 0" class="table-responsive">
      <CTable bordered small class="align-middle mb-0">
        <CTableHead>
          <CTableRow>
            <CTableHeaderCell style="width: 48px">#</CTableHeaderCell>
            <CTableHeaderCell v-for="col in columnDefs" :key="col.register_template.id">
              <div class="d-flex align-items-center gap-1">
                {{ col.register_template.name }}
                <CTooltip v-if="col.register_template.description" :content="col.register_template.description">
                  <template #toggler="{ on }">
                    <CIcon v-on="on" icon="cilInfo" size="sm" class="text-muted" />
                  </template>
                </CTooltip>
              </div>
            </CTableHeaderCell>
          </CTableRow>
        </CTableHead>
        <CTableBody>
          <CTableRow v-for="row in phaseRows" :key="row.phaseIndex">
            <CTableHeaderCell scope="row">{{ row.phaseIndex }}</CTableHeaderCell>
            <CTableDataCell v-for="(cell, colIndex) in row.cells" :key="colIndex">
              <ProgramCell
                v-if="cell"
                :mapping="cell"
                :pending-value="pendingValueFor(cell.measurement_point)"
                :has-pending-change="hasPendingChange(cell.measurement_point)"
                @update:value="(value) => setPending(cell.measurement_point, value)" />
              <span v-else class="text-muted">—</span>
            </CTableDataCell>
          </CTableRow>
        </CTableBody>
      </CTable>
    </div>

    <div class="d-flex gap-2 mt-3">
      <CButton color="primary" :disabled="!hasPending || isSaving" @click="save">
        <CSpinner v-if="isSaving" component="span" size="sm" class="me-1" />
        Save Program {{ program.index + 1 }}
      </CButton>
      <CButton color="secondary" variant="outline" :disabled="!hasPending || isSaving" @click="discard">
        Discard
      </CButton>
    </div>
  </CContainer>
</template>

<script lang="ts" setup>
  import { ref, reactive, computed, watch } from 'vue';
  import axios from 'axios';
  import ProgramCell from './ProgramCell.vue';
  import { useApiCall } from '@/composables/useApi';
  import useAuth from '@/composables/useAuth';
  import type { RegisterMapping } from '@/types/plc';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { Program } from './types';

  type CellValue = MeasurementPoint['last_value'];

  type PhaseRow = {
    phaseIndex: number;
    cells: Array<RegisterMapping | null>;
  };

  const { program } = defineProps<{ program: Program }>();

  const emit = defineEmits<{
    (e: 'update:has-pending-changes', value: boolean): void;
  }>();

  const { execute } = useApiCall();
  const { routePath } = useAuth();

  const metaRegisters = computed<RegisterMapping[]>(() => program.meta?.registers ?? []);

  // Columns are the first phase's registers, ordered by position. Every phase
  // shares the same group_role set, so this defines the whole grid.
  const columnDefs = computed<RegisterMapping[]>(() => {
    if (program.phases.length === 0)
      return [];

    return [...program.phases[0].registers].sort((a, b) => a.position - b.position);
  });

  const phaseRows = computed<PhaseRow[]>(() => {
    const cols = columnDefs.value;

    return program.phases.map((phase) => {
      const byRole: Record<string, RegisterMapping> = {};
      phase.registers.forEach((rm) => {
        const role = rm.register_template.group_role;
        if (role !== null)
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

  // ── Pending changes (keyed by measurement_point id) ──

  const pendingChanges = reactive<Record<number, CellValue>>({});
  const hasPending = computed(() => Object.keys(pendingChanges).length > 0);

  function pendingValueFor(mp: MeasurementPoint) {
    return pendingChanges[mp.id];
  }

  function hasPendingChange(mp: MeasurementPoint) {
    return mp.id in pendingChanges;
  }

  function setPending(mp: MeasurementPoint, value: CellValue) {
    if (value === mp.last_value) {
      delete pendingChanges[mp.id];
      return;
    }

    pendingChanges[mp.id] = value;
  }

  function discard() {
    Object.keys(pendingChanges).forEach((key) => delete pendingChanges[Number(key)]);
  }

  // ── Save (reuses the generic bulk_write endpoint) ──

  const isSaving = ref(false);

  async function save() {
    if (!hasPending.value)
      return;

    isSaving.value = true;

    const updates = Object.entries(pendingChanges).map(([id, value]) => ({
      measurement_point_id: Number(id),
      value
    }));

    const { success, data } = await execute<{ measurement_points: MeasurementPoint[] }>(
      () => axios.post(routePath('measurement_points_bulk_write'), { configuration_updates: updates }),
      {
        showSuccessToast: true,
        successMessage: `Program ${program.index + 1} saved`,
        showErrorToast: true,
        errorTitle: 'Save failed'
      }
    );

    if (success) {
      patchLocalValues(data.measurement_points);
      discard();
    }

    isSaving.value = false;
  }

  function patchLocalValues(refreshed: MeasurementPoint[]) {
    const byId = new Map<number, MeasurementPoint>();
    refreshed.forEach((mp) => byId.set(mp.id, mp));

    const allMappings: RegisterMapping[] = [
      ...metaRegisters.value,
      ...program.phases.flatMap((phase) => phase.registers)
    ];

    allMappings.forEach((rm) => {
      const updated = byId.get(rm.measurement_point.id);
      if (!updated)
        return;

      rm.measurement_point.last_value = updated.last_value;
      rm.measurement_point.last_value_at = updated.last_value_at;
    });
  }

  watch(hasPending, (value) => emit('update:has-pending-changes', value));
</script>

<style scoped>
</style>
