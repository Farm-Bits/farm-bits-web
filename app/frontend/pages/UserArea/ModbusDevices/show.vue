<template>
  <div class="modbus-device-show">
    <CCard>
      <CCardHeader class="d-flex justify-content-between align-items-center">
        <div>
          <h5 class="mb-1">{{ modbusDevice.name }}</h5>
          <div class="text-muted small">
            {{ modbusDevice.model?.full_name }}
            <span v-if="modbusDevice.modbus_firmware_version">
              — {{ modbusDevice.modbus_firmware_version.name }}
            </span>
          </div>
        </div>
        <CTooltip v-if="permissions?.modbus_devices.refresh_values" content="Refresh values">
          <template #toggler="{ on }">
            <CButton
              v-on="on"
              color="light"
              size="sm"
              :disabled="isRefreshing"
              @click="refreshValues">
              <CIcon icon="cilSync" :class="{ 'spin': isRefreshing }" />
            </CButton>
          </template>
        </CTooltip>
      </CCardHeader>

      <CCardBody>
        <div v-if="registerMappings.length === 0" class="text-center py-5">
          <CIcon icon="cilSpeedometer" size="3xl" class="text-muted mb-3" />
          <h5 class="text-muted">No measurement registers</h5>
          <p class="text-muted mb-0">
            This device doesn't have any measurement registers configured.
          </p>
        </div>

        <CTable v-else hover responsive class="measurement-points-table mb-0">
          <CTableHead>
            <CTableRow class="bg-light">
              <CTableHeaderCell style="width: 50px">Status</CTableHeaderCell>
              <CTableHeaderCell>Device Name</CTableHeaderCell>
              <CTableHeaderCell>Type</CTableHeaderCell>
              <CTableHeaderCell>Register</CTableHeaderCell>
              <CTableHeaderCell>Segment</CTableHeaderCell>
              <CTableHeaderCell style="width: 120px">Current Value</CTableHeaderCell>
              <CTableHeaderCell style="width: 100px">Unit</CTableHeaderCell>
              <CTableHeaderCell style="width: 80px" class="text-center">Actions</CTableHeaderCell>
            </CTableRow>
          </CTableHead>
          <CTableBody>
            <MeasurementRow
              v-for="mapping in registerMappings"
              :key="mapping.measurement_point.id"
              :registerMapping="mapping"
              :segments="segments"
              :measurementSubtypes="measurementSubtypes"
              @viewHistory="openHistoryModal"
              @edit="openEditModal"
              @update="handleMeasurementPointUpdate" />
          </CTableBody>
        </CTable>
      </CCardBody>
    </CCard>

    <CModal
      :visible="showEditModal"
      @close="closeEditModal"
      size="lg"
      backdrop="static">
      <CModalHeader>
        <CModalTitle>Configure Device</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <!-- <MeasurementPointSimpleForm
          v-if="selectedMapping"
          :registerMapping="selectedMapping"
          :segments="segments"
          :measurementSubtypes="measurementSubtypes"
          @submit="handleMeasurementPointUpdate"
          @cancel="closeEditModal" /> -->
      </CModalBody>
    </CModal>

    <MeasurementPointAnalyticsModal
      :visible="showHistoryModal"
      :measurement-points="historyMeasurementPoints"
      @close="closeHistoryModal" />
  </div>
</template>

<script lang="ts" setup>
  import { computed, ref } from 'vue';
  import axios from 'axios';
  import MeasurementRow from '@/components/MeasurementRow.vue';
  // import MeasurementPointSimpleForm from '@/components/MeasurementPointSimpleForm/index.vue';
  import MeasurementPointAnalyticsModal from '@/components/MeasurementPointAnalyticsModal.vue';
  import usePermissions from '@/composables/usePermissions';
  import useAuth from '@/composables/useAuth';
  import { useApiCall } from '@/composables/useApi';
  import type { MeasurementPoint, MeasurementSubtype } from '@/types/measurementPoint';
  import type { Segment } from '@/types/location';
  import type { RegisterMapping } from '@/types/plc';
  import type { ModbusDevice } from '@/types/modbusDevice';
  import type { LiveMeasurementPoint } from '@/types/analytics';

  const { currentSite, pageProps } = useAuth<{
    modbusDevice: ModbusDevice;
    registerMappings: RegisterMapping[];
    segments: Segment[];
    measurementSubtypes: MeasurementSubtype[];
  }>();
  const segments = computed(() => currentSite.value?.segments || []);
  const modbusDevice = computed(() => pageProps.value.modbusDevice);
  const registerMappings = computed(() => pageProps.value.registerMappings);
  const measurementSubtypes = computed(() => pageProps.value.measurementSubtypes);

  const { permissions } = usePermissions();
  const { execute } = useApiCall();

  // ── Edit modal ──

  const showEditModal = ref(false);
  const selectedMapping = ref<RegisterMapping | null>(null);

  function openEditModal(mapping: RegisterMapping) {
    selectedMapping.value = mapping;
    showEditModal.value = true;
  }

  function closeEditModal() {
    showEditModal.value = false;
    selectedMapping.value = null;
  }

  function handleMeasurementPointUpdate(
    updatedMeasurementPoint: MeasurementPoint,
    siblingMeasurementPoints: MeasurementPoint[]
  ) {
    const updatedById = new Map<number, MeasurementPoint>();
    updatedById.set(updatedMeasurementPoint.id, updatedMeasurementPoint);
    siblingMeasurementPoints.forEach((mp) => updatedById.set(mp.id, mp));

    registerMappings.value.forEach((mapping) => {
      const updated = updatedById.get(mapping.measurement_point.id);
      if (updated) {
        Object.assign(mapping.measurement_point, updated);
      }
    });

    closeEditModal();
  }

  // ── History modal ──

  const showHistoryModal = ref(false);
  const historyMeasurementPoints = ref<LiveMeasurementPoint[]>([]);

  function openHistoryModal(mapping: RegisterMapping) {
    const measurementSubtype = measurementSubtypes.value.find(
      (subtype) => subtype.id === mapping.measurement_point.measurement_subtype_id
    );
    historyMeasurementPoints.value = [{
      ...mapping.measurement_point,
      measurement_subtype: measurementSubtype ?? null,
      plc_id: null,
      modbus_device_id: modbusDevice.value.id,
      device_owner_name: modbusDevice.value.name,
      register_template: mapping.register_template,
      interface_communication_type: null,
      interface_io_number: null
    }];
    showHistoryModal.value = true;
  }

  function closeHistoryModal() {
    showHistoryModal.value = false;
    historyMeasurementPoints.value = [];
  }

  // ── Refresh values ──

  const isRefreshing = ref(false);

  async function refreshValues() {
    isRefreshing.value = true;

    await execute(
      () => axios.post(`/user/modbus_devices/${modbusDevice.value.id}/refresh_values`),
      {
        showSuccessToast: true,
        successMessage: 'Refresh started',
        showErrorToast: true,
        errorTitle: 'Refresh failed'
      }
    );

    isRefreshing.value = false;
  }
</script>

<style scoped>
  .modbus-device-show {
    padding: 1rem;
  }

  .measurement-points-table {
    font-size: 0.875rem;
  }

  .measurement-points-table :deep(th) {
    font-weight: 600;
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.025em;
    color: #6b7280;
    border-bottom: 2px solid #e5e7eb;
  }

  .measurement-points-table :deep(td) {
    vertical-align: middle;
    border-bottom: 1px solid #f3f4f6;
  }

  .measurement-points-table :deep(tr:hover) {
    background-color: #f9fafb;
  }

  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }

  .spin {
    animation: spin 1s linear infinite;
  }
</style>
