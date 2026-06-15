<template>
  <CModal :visible="visible" size="xl" backdrop="static" @close="handleClose">
    <CModalHeader>
      <CModalTitle v-if="measurementPoint">Configure — {{ measurementPoint.name }}</CModalTitle>
    </CModalHeader>
    <CModalBody>
      <div v-if="loading" class="text-center py-5">
        <CSpinner color="primary" />
        <p class="text-body-secondary mt-2">Loading configuration...</p>
      </div>
      <OperationModePanel
        v-else-if="data"
        :mappings="data.register_mappings"
        :config-values="configValues"
        :group-labels="data.group_labels"
        :available-sources="data.available_sources"
        @value-change="handleValueChange"
        @write="handleImmediateWrite" />
    </CModalBody>
    <CModalFooter v-if="data && hasChanges">
      <CButton color="secondary" variant="ghost" @click="handleClose">Cancel</CButton>
      <CButton color="primary" :disabled="saving" @click="handleSave">
        {{ saving ? 'Saving...' : 'Save & Apply' }}
      </CButton>
    </CModalFooter>
  </CModal>
</template>

<script lang="ts" setup>
  import { ref, reactive, computed, watch } from 'vue';
  import axios from 'axios';
  import OperationModePanel from '@/components/OperationMode/OperationModePanel.vue';
  import useAuth from '@/composables/useAuth';
  import { useApiCall } from '@/composables/useApi';
  import type { ConfigValues } from '@/composables/useConfigurationValues';
  import type { LiveMeasurementPoint, OperationModeConfigResponse } from '@/types/analytics';
  import type { MeasurementPoint } from '@/types/measurementPoint';

  const { visible, measurementPoint } = defineProps<{
    visible: boolean;
    measurementPoint: LiveMeasurementPoint | null;
  }>();

  const emit = defineEmits<{
    (e: 'close'): void;
    (e: 'updated', measurementPoints: MeasurementPoint[]): void;
  }>();

  const { routePath } = useAuth();
  const { execute } = useApiCall();

  const loading = ref(false);
  const saving = ref(false);
  const data = ref<OperationModeConfigResponse | null>(null);
  const configValues = reactive<ConfigValues>({});
  const editedIds = ref(new Set<MeasurementPoint['id']>());

  const hasChanges = computed(() => editedIds.value.size > 0);

  watch(() => visible, (isOpen) => {
    if (!isOpen || !measurementPoint)
      return;

    load(measurementPoint.id);
  });

  async function load(mpId: number) {
    loading.value = true;
    editedIds.value = new Set();
    clearConfigValues();

    const { success, data: response } = await execute<OperationModeConfigResponse>(
      () => axios.get(routePath('measurement_points_operation_mode_config', { id: mpId })),
      { showErrorToast: true, errorTitle: 'Could not load configuration' }
    );

    if (success) {
      data.value = response;
      for (const rm of response.register_mappings)
        configValues[rm.measurement_point.id] = rm.measurement_point.last_value;
    }

    loading.value = false;
  }

  function handleValueChange(mpId: MeasurementPoint['id'], value: MeasurementPoint['last_value']) {
    configValues[mpId] = value;
    editedIds.value.add(mpId);
  }

  async function handleImmediateWrite(
    mpId: MeasurementPoint['id'],
    value: NonNullable<MeasurementPoint['last_value']>
  ) {
    const { success, data: mp } = await execute<MeasurementPoint>(
      () => axios.post(routePath('measurement_points_write', { id: mpId }), { value }),
      { showErrorToast: true, errorTitle: 'Command failed' }
    );

    if (success) {
      configValues[mp.id] = mp.last_value;
      emit('updated', [mp]);
    }
  }

  async function handleSave() {
    if (editedIds.value.size === 0 || !measurementPoint)
      return;

    saving.value = true;

    const updates = Array.from(editedIds.value).map((mpId) => ({
      measurement_point_id: mpId,
      value: configValues[mpId]
    }));

    const { success, data: response } = await execute<{ measurement_points: MeasurementPoint[] }>(
      () => axios.post(
        routePath('measurement_points_bulk_write'),
        { configuration_updates: updates }
      ),
      { showErrorToast: true, errorTitle: 'Save failed' }
    );

    saving.value = false;

    if (success) {
      emit('updated', response.measurement_points);
      editedIds.value = new Set();
      emit('close');
    }
  }

  function handleClose() {
    data.value = null;
    clearConfigValues();
    emit('close');
  }

  function clearConfigValues() {
    Object.keys(configValues).forEach((key) => delete configValues[Number(key)]);
  }
</script>
