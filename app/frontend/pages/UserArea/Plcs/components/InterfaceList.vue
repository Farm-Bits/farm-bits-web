<template>
  <div class="interface-list">
    <!-- Empty State -->
    <div v-if="interfaces.length === 0" class="text-center py-5">
      <CIcon icon="cilPlug" size="4xl" class="text-muted mb-3" />
      <h5 class="text-muted">No {{ communicationTypeLabel }} Interfaces</h5>
      <p class="text-muted mb-0">
        This controller doesn't have any {{ communicationTypeLabel.toLowerCase() }} interfaces configured.
      </p>
    </div>

    <!-- Table -->
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
        <InterfaceRow
          v-for="iface in interfaces" :key="iface.id"
          :iface="iface"
          :segments="segments"
          :measurementSubtypes="measurementSubtypes"
          @viewHistory="openHistoryModal"
          @edit="openEditModal"
          @update="handleMeasurementPointSubmit" />
      </CTableBody>
    </CTable>

    <!-- Edit Measurement Point Modal -->
    <CModal
      :visible="showEditModal"
      @close="closeEditModal"
      size="lg"
      backdrop="static">
      <CModalHeader>
        <CModalTitle>Configure Device</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <MeasurementPointForm
          v-if="selectedInterface"
          :iface="selectedInterface"
          :segments="segments"
          :measurementSubtypes="measurementSubtypes"
          @submit="handleMeasurementPointSubmit"
          @cancel="closeEditModal" />
      </CModalBody>
    </CModal>

    <!-- Analytics Modal -->
    <MeasurementPointAnalyticsModal
      :visible="showHistoryModal"
      :measurement-points="historyMeasurementPoints"
      @close="closeHistoryModal" />
  </div>
</template>

<script lang="ts" setup>
  import { ref, computed } from 'vue';
  import InterfaceRow from './InterfaceRow.vue';
  import MeasurementPointForm from '@/components/MeasurementPointForm/index.vue';
  import MeasurementPointAnalyticsModal from '@/components/MeasurementPointAnalyticsModal.vue';
  import type { Segment } from '@/types/location';
  import type { MeasurementPoint, MeasurementSubtype } from '@/types/measurementPoint';
  import type {
    CommunicationType,
    InterfaceWithMeasurementPoints,
    Plc,
    RegisterMapping
  } from '@/types/plc';
  import { COMMUNICATION_TYPE_TABS } from '../types';
  import type { LiveMeasurementPoint } from '@/types/analytics';

  const {
    plc,
    interfaces,
    communicationType,
    segments,
    measurementSubtypes
  } = defineProps<{
    plc: Plc;
    interfaces: InterfaceWithMeasurementPoints[];
    communicationType: CommunicationType;
    segments: Segment[];
    measurementSubtypes: MeasurementSubtype[];
  }>();

  const emit = defineEmits<{
    (
      e: 'update-interface',
      updatedMeasurementPoint: MeasurementPoint,
      siblingMeasurementPoints: MeasurementPoint[]
    ): void;
  }>();

  const showEditModal = ref(false);
  const selectedInterface = ref<InterfaceWithMeasurementPoints | null>(null);

  const showHistoryModal = ref(false);
  const historyMeasurementPoints = ref<LiveMeasurementPoint[]>([]);

  const communicationTypeLabel = computed(() => {
    const tab = COMMUNICATION_TYPE_TABS.find((t) => t.key === communicationType);
    return tab ? tab.label : 'Unknown';
  });

  function openEditModal(iface: InterfaceWithMeasurementPoints) {
    selectedInterface.value = iface;
    showEditModal.value = true;
  }

  function closeEditModal() {
    showEditModal.value = false;
    selectedInterface.value = null;
  }

  function openHistoryModal(ioNumber: number, registerMapping: RegisterMapping) {
    const measurementSubtype = measurementSubtypes.find(
      (subtype) => subtype.id === registerMapping.measurement_point.measurement_subtype_id
    );
    historyMeasurementPoints.value = [{
      ...registerMapping.measurement_point,
      measurement_subtype: measurementSubtype ?? null,
      plc_id: plc.id,
      modbus_device_id: null,
      device_owner_name: plc.name,
      register_template: registerMapping.register_template,
      interface_communication_type: communicationType,
      interface_io_number: ioNumber
    }];
    showHistoryModal.value = true;
  }

  function closeHistoryModal() {
    showHistoryModal.value = false;
    historyMeasurementPoints.value = [];
  }

  function handleMeasurementPointSubmit(
    updatedMeasurementPoint: MeasurementPoint,
    siblingMeasurementPoints: MeasurementPoint[]
  ) {
    emit('update-interface', updatedMeasurementPoint, siblingMeasurementPoints);
    closeEditModal();
  }
</script>

<style scoped>
  .interface-list {
    min-height: 300px;
  }

  .interface-accordion {
    border: none;
  }

  .interface-accordion :deep(.accordion-item) {
    border: none;
    border-bottom: 1px solid #e5e7eb;
  }

  .interface-accordion :deep(.accordion-item:last-child) {
    border-bottom: none;
  }

  .interface-accordion :deep(.accordion-header) {
    background: transparent;
  }

  .interface-accordion :deep(.accordion-button) {
    background: #f9fafb;
    box-shadow: none;
  }

  .interface-accordion :deep(.accordion-button:not(.collapsed)) {
    background: #f3f4f6;
    color: inherit;
  }

  .interface-accordion :deep(.accordion-body) {
    padding: 0;
  }
</style>
