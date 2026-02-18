<template>
  <CCard>
    <CCardHeader>
      <strong>PLC Configuration</strong>
    </CCardHeader>
    <CCardBody>
      <template v-if="configurationMappings.length === 0">
        <p class="text-body-secondary mb-0">No configuration registers available.</p>
      </template>

      <template v-else>
        <div
          v-for="(group, groupIndex) in groupedRegisters"
          :key="group.groupName || 'ungrouped'">
          <h6 v-if="group.groupName" class="mb-3" :class="{ 'mt-4': groupIndex > 0 }">
            {{ formatGroupName(group.groupName) }}
          </h6>

          <div v-for="registerMapping in group.registerMappings" :key="registerMapping.measurement_point.id">
            <div
              v-if="isVisible(registerMapping)"
              class="row align-items-center py-3 border-bottom">
              <div class="col-md-4">
                <label class="form-label mb-0 fw-medium">
                  {{ registerMapping.register_template.label }}
                </label>
                <div v-if="registerMapping.register_template.description" class="text-muted small">
                  {{ registerMapping.register_template.description }}
                </div>
              </div>

              <div class="col-md-5">
                <RegisterField
                  :model-value="editValues[registerMapping.measurement_point.id] ?? null"
                  :registerMapping="registerMapping"
                  :isEditing="isEditing(registerMapping.measurement_point.id)"
                  :disabled="isSaving[registerMapping.measurement_point.id]"
                  :validationError="validationErrors[registerMapping.measurement_point.id]"
                  @update:model-value="handleValueChange(registerMapping.measurement_point.id, $event)" />
              </div>

              <div class="col-md-3 text-end">
                <div v-if="!isEditing(registerMapping.measurement_point.id)">
                  <CButton
                    v-if="!registerMapping.register_template.read_only"
                    size="sm"
                    @click="startEditing(registerMapping)">
                    <CIcon icon="cilPencil" class="me-1" />
                    Edit
                  </CButton>
                  <CBadge v-else color="secondary" class="ms-2">
                    Read Only
                  </CBadge>
                </div>

                <div v-else class="d-flex gap-2 justify-content-end">
                  <CButton
                    size="sm"
                    color="primary"
                    :disabled="!hasChanges(registerMapping.measurement_point.id) ||
                              hasValidationError(registerMapping.measurement_point.id) ||
                              isSaving[registerMapping.measurement_point.id]"
                    @click="saveField(registerMapping)">
                    <CSpinner
                      v-if="isSaving[registerMapping.measurement_point.id]"
                      component="span"
                      size="sm"
                      aria-hidden="true"
                      class="me-1" />
                    <CIcon v-else icon="cilCheck" class="me-1" />
                    Update
                  </CButton>
                  <CButton
                    size="sm"
                    color="secondary"
                    :disabled="isSaving[registerMapping.measurement_point.id]"
                    @click="cancelEditing(registerMapping.measurement_point.id)">
                    <CIcon icon="cilX" class="me-1" />
                    Cancel
                  </CButton>
                </div>
              </div>
            </div>
          </div>
        </div>
      </template>
    </CCardBody>
  </CCard>
</template>

<script setup lang="ts">
  import { computed, reactive, ref, toRef } from 'vue';
  import axios from 'axios';
  import RegisterField from '@/components/RegisterField.vue';
  import { useRegisterVisibility } from '@/composables/useRegisterVisibility';
  import { useConfigurationValues } from '@/composables/useConfigurationValues';
  import { useApiCall } from '@/composables/useApi';
  import { formatGroupName } from '@/utils/registerUtils';
  import { ROUTES } from '@/types/permissions';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { PlcWithInterfaces, RegisterMapping } from '@/types/plc';

  const { plc } = defineProps<{
    plc: PlcWithInterfaces;
  }>();

  const { execute } = useApiCall();

  const configurationMappings = computed(() => {
    return plc.register_mappings.filter(registerMapping => {
      const category = registerMapping.register_template.category;
      return category === 'configuration' || category === 'diagnostic';
    });
  });

  const {
    configValues,
    initializeValues
  } = useConfigurationValues(toRef(() => configurationMappings.value));

  initializeValues();

  const { isVisible } = useRegisterVisibility(
    toRef(() => configurationMappings.value),
    toRef(() => configValues)
  );

  const editingFields = ref<Set<MeasurementPoint['id']>>(new Set());
  const editValues = reactive<Record<MeasurementPoint['id'], MeasurementPoint['last_value']>>({});
  const originalValues = reactive<Record<MeasurementPoint['id'], MeasurementPoint['last_value']>>({});
  const validationErrors = reactive<Record<MeasurementPoint['id'], string | null>>({});
  const isSaving = reactive<Record<MeasurementPoint['id'], boolean>>({});

  configurationMappings.value.forEach((registerMapping) => {
    originalValues[registerMapping.measurement_point.id] = registerMapping.measurement_point.last_value ?? null;
  });

  const groupedRegisters = computed(() => {
    const groups = new Map<string | null, RegisterMapping[]>();

    configurationMappings.value.forEach((registerMapping) => {
      const groupName = registerMapping.register_template.group_name;
      if (!groups.has(groupName)) {
        groups.set(groupName, []);
      }
      groups.get(groupName)!.push(registerMapping);
    });

    return Array.from(groups.entries())
      .map(([groupName, registerMappings]) => ({
        groupName,
        registerMappings: [...registerMappings].sort((a, b) => a.position - b.position)
      }))
      .sort((a, b) => {
        if (a.groupName === null) return 1;
        if (b.groupName === null) return -1;
        return a.groupName.localeCompare(b.groupName);
      });
  });

  function isEditing(measurementPointId: MeasurementPoint['id']) {
    return editingFields.value.has(measurementPointId);
  }

  function hasChanges(measurementPointId: MeasurementPoint['id']) {
    return editValues[measurementPointId] !== originalValues[measurementPointId];
  }

  function hasValidationError(measurementPointId: MeasurementPoint['id']) {
    return validationErrors[measurementPointId] !== null &&
          validationErrors[measurementPointId] !== undefined;
  }

  function startEditing(registerMapping: RegisterMapping) {
    const id = registerMapping.measurement_point.id;
    editingFields.value.add(id);
    editValues[id] = registerMapping.measurement_point.last_value ?? null;
    validationErrors[id] = null;
  }

  function cancelEditing(measurementPointId: MeasurementPoint['id']) {
    editingFields.value.delete(measurementPointId);
    delete editValues[measurementPointId];
    validationErrors[measurementPointId] = null;
  }

  function handleValueChange(measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']) {
    editValues[measurementPointId] = value;
    validationErrors[measurementPointId] = null;
  }

  async function saveField(registerMapping: RegisterMapping) {
    const measurementPointId = registerMapping.measurement_point.id;

    if (!hasChanges(measurementPointId) || hasValidationError(measurementPointId)) {
      return;
    }

    isSaving[measurementPointId] = true;

    const url = ROUTES.measurement_points_write.path.replace(
      ':id',
      String(measurementPointId)
    );

    const { success, data } = await execute<MeasurementPoint>(
      () => axios.post(url, { value: editValues[measurementPointId] }),
      {
        showSuccessToast: true,
        successMessage: 'Value updated successfully',
        showErrorToast: true,
        errorTitle: 'Error'
      }
    );

    if (success) {
      originalValues[measurementPointId] = data.last_value;
      const mapping = configurationMappings.value.find(m => m.measurement_point.id === measurementPointId);
      if (mapping)
        mapping.measurement_point.last_value = data.last_value;

      cancelEditing(measurementPointId);
    }

    isSaving[measurementPointId] = false;
  }
</script>

<style scoped>
  h6.mt-4 {
    padding-top: 1.5rem;
    border-top: 1px solid var(--cui-border-color);
  }

  @media (max-width: 768px) {
    .row.align-items-center .col-md-4,
    .row.align-items-center .col-md-5,
    .row.align-items-center .col-md-3 {
      margin-bottom: 0.5rem;
    }

    .text-end {
      text-align: left !important;
    }
  }
</style>
