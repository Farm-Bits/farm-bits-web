<template>
  <div>
    <!-- Assigned PLCs List -->
    <div class="mb-3">
      <div class="d-flex justify-content-between align-items-center mb-2">
        <h6 class="mb-0">Assign PLCs</h6>
        <span v-if="modelValue.length > 0" class="text-muted small">
          {{ modelValue.length }} PLC{{ modelValue.length !== 1 ? 's' : '' }} assigned
        </span>
      </div>

      <div v-if="modelValue.length === 0" class="text-muted text-center py-3">
        No PLCs assigned. Click "Add PLC" to connect a PLC to this terminal.
      </div>

      <div
        v-for="(plc, index) in modelValue"
        :key="index"
        class="plc-assignment-card">
        <div class="card-body">
          <div class="d-flex align-items-center justify-content-between gap-3">
            <!-- PLC Info Section -->
            <div class="flex-grow-1">
              <!-- Editable Name Input -->
              <div class="mb-2">
                <CFormLabel class="small fw-semibold mb-1">Display Name</CFormLabel>
                <CFormInput
                  :model-value="plc.customName"
                  size="sm"
                  placeholder="Enter PLC name"
                  @update:model-value="updatePlcName(index, $event)" />
              </div>

              <!-- PLC Metadata -->
              <div class="plc-metadata">
                <span class="metadata-item">
                  <strong>Label:</strong> {{ plc.label }}
                </span>
                <span class="metadata-separator">•</span>
                <span class="metadata-item">
                  <strong>Version:</strong> {{ plc.plc_version.name }}
                </span>
                <span class="metadata-separator">•</span>
                <span class="metadata-item">
                  <strong>Slave:</strong> {{ plc.slave }}
                </span>
              </div>
            </div>

            <!-- Actions -->
            <div class="d-flex flex-column gap-2">
              <CTooltip content="Remove PLC">
                <template #toggler="{ id, on }">
                  <CButton
                    v-on="on"
                    color="danger"
                    variant="ghost"
                    size="sm"
                    @click="removePlc(plc)">
                    <CIcon icon="cilTrash" />
                  </CButton>
                </template>
              </CTooltip>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Available PLCs Grid -->
    <div>
      <div class="d-flex justify-content-between align-items-center mb-2">
        <h6 class="mb-0">Available PLCs</h6>
        <span v-if="filteredAvailablePlcs.length > 0" class="text-muted small">
          {{ filteredAvailablePlcs.length }} available(s)
        </span>
      </div>

      <div v-if="isAllAvailablePlcsAssigned" class="text-muted text-center py-3">
        No more PLCs to assign.
      </div>

      <div v-else class="available-plcs">
        <div class="plcs-grid">
          <CCard
            v-for="plc in filteredAvailablePlcs"
            :key="plc.id"
            class="plc-card">
            <CCardBody class="d-flex flex-column h-100">
              <div class="flex-grow-1">
                <CCardTitle class="mb-2">{{ plc.name }}</CCardTitle>
                <CCardText v-if="plc.label != plc.name" class="text-muted small mb-1">
                  <strong>Label:</strong> {{ plc.label }}
                </CCardText>
                <CCardText class="text-muted small mb-1">
                  <strong>Version:</strong> {{ plc.plc_version.name }}
                </CCardText>
                <CCardText class="text-muted small">
                  <strong>Slave:</strong> {{ plc.slave }}
                </CCardText>
              </div>
              <CTooltip content="PLC with same IP already assigned">
                <template #toggler="{ id, on }">
                  <span
                    class="d-inline-block"
                    :tabindex="0"
                    :aria-describedby="id"
                    v-on="ipAlreadyAssigned(plc.private_ip) ? on : {}">
                    <CButton
                      color="success"
                      size="sm"
                      variant="outline"
                      class="mt-3 w-100"
                      :disabled="ipAlreadyAssigned(plc.private_ip)"
                      @click="selectPlc(plc)">
                      <CIcon icon="cilPlus" class="me-1" />
                      Add PLC
                    </CButton>
                  </span>
                </template>
              </CTooltip>
            </CCardBody>
          </CCard>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import type { Plc } from '@/types/plc';

  const props = defineProps<{
    modelValue: (Plc & { customName: string })[];
    availablePlcs: Plc[];
  }>();

  const emit = defineEmits<{
    (e: 'update:modelValue', value: (Plc & { customName: string })[]): void;
  }>();

  const filteredAvailablePlcs = computed(() => {
    return props.availablePlcs.filter(
      (plc) => !props.modelValue.some((a) => a.id === plc.id)
    );
  });

  const isAllAvailablePlcsAssigned = computed(() => {
    const assignedPlcIds = props.modelValue.map((a) => a.id);
    return props.availablePlcs.every((plc) => assignedPlcIds.includes(plc.id));
  });

  function ipAlreadyAssigned(private_ip: Plc['private_ip']): boolean {
    return props.modelValue.some((a) => a.private_ip === private_ip);
  }

  function selectPlc(plc: Plc) {
    const newAssignments = [
      ...props.modelValue,
      {
        ...plc,
        customName: plc.name
      }
    ];
    emit('update:modelValue', newAssignments);
  }

  function removePlc(plc: Plc) {
    const newAssignments = props.modelValue.filter((a) => a.id !== plc.id);
    emit('update:modelValue', newAssignments);
  }

  function updatePlcName(index: number, newName: string) {
    const newAssignments = [...props.modelValue];
    newAssignments[index].customName = newName;
    emit('update:modelValue', newAssignments);
  }
</script>

<style scoped>
  .available-plcs {
    margin-top: 0.25rem;
  }

  .plcs-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(12rem, 1fr));
    gap: 1rem;
    padding: 1rem;
    background-color: white;
    border-radius: 0.375rem;
    box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  }

  .plc-card {
    transition: all 0.2s ease;
    border: 1px solid #e5e7eb;
  }

  .plc-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  }

  .plc-assignment-card {
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 0.5rem;
    margin-bottom: 0.75rem;
    transition: all 0.2s ease;
  }

  .plc-assignment-card:hover {
    border-color: #d1d5db;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  }

  .plc-assignment-card .card-body {
    padding: 1rem;
  }

  .plc-metadata {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 0.813rem;
    color: #6b7280;
  }

  .metadata-item strong {
    color: #374151;
    font-weight: 600;
  }

  .metadata-separator {
    color: #d1d5db;
  }
</style>
