<template>
  <CModal
    :visible="visible"
    size="sm"
    backdrop="static"
    @close="emit('close')">
    <CModalHeader>
      <CModalTitle>{{ title }}</CModalTitle>
    </CModalHeader>
    <CModalBody>
      <template
        v-for="rm in paramMappings"
        :key="rm.measurement_point.id">
        <div
          v-if="isVisible(rm)"
          class="mb-3">
          <CFormLabel class="fw-semibold d-flex align-items-center gap-2">
            {{ rm.register_template.name }}
            <CTooltip
              v-if="rm.register_template.description"
              :content="rm.register_template.description">
              <template #toggler="{ on }">
                <CIcon v-on="on" icon="cilInfo" size="sm" class="text-muted" />
              </template>
            </CTooltip>
          </CFormLabel>
          <RegisterField
            :register-mapping="rm"
            :model-value="localValues[rm.measurement_point.id]"
            :is-editing="true"
            @update:model-value="handleValueChange(rm.measurement_point.id, $event)" />
        </div>
      </template>
    </CModalBody>
    <CModalFooter>
      <CButton color="secondary" variant="ghost" @click="emit('close')">
        Cancel
      </CButton>
      <CButton color="primary" @click="handleConfirm">
        Confirm
      </CButton>
    </CModalFooter>
  </CModal>
</template>

<script lang="ts" setup>
  import { reactive, watch, toRef, computed } from 'vue';
  import RegisterField from '@/components/RegisterField.vue';
  import { useRegisterVisibility } from '@/composables/useRegisterVisibility';
  import type { RegisterMapping } from '@/types/plc';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { ConfigValues } from '@/composables/useConfigurationValues';

  const props = defineProps<{
    visible: boolean;
    title: string;
    paramMappings: RegisterMapping[];
    /** All mappings in the parent scope — needed for visibility condition resolution */
    allMappings: RegisterMapping[];
    pendingWrite?: { measurementPointId: number; value: string | number } | null;
  }>();

  const emit = defineEmits<{
    (e: 'close'): void;
    (e: 'confirm', values: Record<MeasurementPoint['id'], NonNullable<MeasurementPoint['last_value']>>): void;
  }>();

  // Local values for editing
  const localValues = reactive<ConfigValues>({});

  // Re-initialize when the modal opens
  watch(() => props.visible, (isVisible) => {
    if (!isVisible)
      return;

    for (const rm of props.paramMappings) {
      const mpId = rm.measurement_point.id;
      const existing = rm.measurement_point.last_value;
      const defaultVal = rm.register_template.default_value;
      localValues[mpId] = existing ?? defaultVal ?? null;
    }
  });

  function handleValueChange(mpId: MeasurementPoint['id'], value: MeasurementPoint['last_value']) {
    localValues[mpId] = value;
  }

  // Visibility — evaluated against localValues so conditional fields react
  const configValuesRef = computed<ConfigValues>(() => {
    // Merge parent mapping values with local edits
    const merged: ConfigValues = {};
    for (const rm of props.allMappings) {
      merged[rm.measurement_point.id] = rm.measurement_point.last_value;
    }
    // Override with local values
    for (const [mpIdStr, value] of Object.entries(localValues)) {
      merged[Number(mpIdStr)] = value;
    }
    // Inject the pending command/enable value so visibility conditions
    // that depend on it (e.g. "show duration when command = Timed") resolve correctly
    if (props.pendingWrite) {
      merged[props.pendingWrite.measurementPointId] = String(props.pendingWrite.value);
    }
    return merged;
  });

  const { isVisible } = useRegisterVisibility(
    toRef(props, 'allMappings'),
    configValuesRef
  );

  function handleConfirm() {
    const values: Record<MeasurementPoint['id'], NonNullable<MeasurementPoint['last_value']>> = {};
    for (const rm of props.paramMappings) {
      const mpId = rm.measurement_point.id;
      const val = localValues[mpId];
      if (val !== null && val !== undefined) {
        values[mpId] = typeof val === 'string' ? val : Number(val);
      }
    }
    emit('confirm', values);
  }
</script>
