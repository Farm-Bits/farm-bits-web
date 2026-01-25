<template>
  <div class="alerts-tab py-3">
    <div v-if="!enabled" class="text-center py-5 text-muted">
      <CIcon icon="cilBell" size="3xl" class="mb-3" />
      <p>Select a measurement type first to configure alerts.</p>
    </div>

    <div v-else>
      <div class="row g-4">
        <div class="col-md-6">
          <div class="mb-3">
            <CFormLabel class="fw-semibold">Alarm Low Threshold</CFormLabel>
            <div class="input-group">
              <CFormInput
                :model-value="modelValue.alarm_low"
                @update:model-value="updateField('alarm_low', $event ? parseFloat($event) : null)"
                :invalid="v$.alarm_low.$error"
                type="number"
                step="any"
                placeholder="e.g., 0" />
              <span v-if="unit" class="input-group-text">{{ unit }}</span>
            </div>
            <CFormFeedback v-if="v$.alarm_low.$error" invalid>
              {{ v$.alarm_low.$errors[0].$message }}
            </CFormFeedback>
            <div class="form-text">
              Trigger an alarm when value drops below this level.
            </div>
          </div>

          <div class="mb-3">
            <CFormLabel class="fw-semibold">Warning Low Threshold</CFormLabel>
            <div class="input-group">
              <CFormInput
                :model-value="modelValue.warning_low"
                @update:model-value="updateField('warning_low', $event ? parseFloat($event) : null)"
                :invalid="v$.warning_low.$error"
                type="number"
                step="any"
                placeholder="e.g., 10" />
              <span v-if="unit" class="input-group-text">{{ unit }}</span>
            </div>
            <CFormFeedback v-if="v$.warning_low.$error" invalid>
              {{ v$.warning_low.$errors[0].$message }}
            </CFormFeedback>
            <div class="form-text">
              Show a warning when value drops below this level.
            </div>
          </div>
        </div>

        <div class="col-md-6">
          <div class="mb-3">
            <CFormLabel class="fw-semibold">Warning High Threshold</CFormLabel>
            <div class="input-group">
              <CFormInput
                :model-value="modelValue.warning_high"
                @update:model-value="updateField('warning_high', $event ? parseFloat($event) : null)"
                :invalid="v$.warning_high.$error"
                type="number"
                step="any"
                placeholder="e.g., 80" />
              <span v-if="unit" class="input-group-text">{{ unit }}</span>
            </div>
            <CFormFeedback v-if="v$.warning_high.$error" invalid>
              {{ v$.warning_high.$errors[0].$message }}
            </CFormFeedback>
            <div class="form-text">
              Show a warning when value exceeds this level.
            </div>
          </div>

          <div class="mb-3">
            <CFormLabel class="fw-semibold">Alarm High Threshold</CFormLabel>
            <div class="input-group">
              <CFormInput
                :model-value="modelValue.alarm_high"
                @update:model-value="updateField('alarm_high', $event ? parseFloat($event) : null)"
                :invalid="v$.alarm_high.$error"
                type="number"
                step="any"
                placeholder="e.g., 100" />
              <span v-if="unit" class="input-group-text">{{ unit }}</span>
            </div>
            <CFormFeedback v-if="v$.alarm_high.$error" invalid>
              {{ v$.alarm_high.$errors[0].$message }}
            </CFormFeedback>
            <div class="form-text">
              Trigger an alarm when value exceeds this level.
            </div>
          </div>
        </div>
      </div>

      <div v-if="hasAnyThreshold" class="mt-4">
        <h6 class="text-muted mb-3">Threshold Preview</h6>
        <ThresholdVisualization
          :alarm-low="modelValue.alarm_low"
          :alarm-high="modelValue.alarm_high"
          :warning-low="modelValue.warning_low"
          :warning-high="modelValue.warning_high"
          :unit="unit" />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import type { NestedValidations } from '@vuelidate/core';
  import ThresholdVisualization from './ThresholdVisualization.vue';
  import type { MeasurementSubtype } from '@/types/measurementPoint';

  type AlertsFormData = {
    alarm_low: number | null;
    alarm_high: number | null;
    warning_low: number | null;
    warning_high: number | null;
  };

  const { modelValue, selectedMeasurementSubtype, unitOverride, v$ } = defineProps<{
    modelValue: AlertsFormData;
    selectedMeasurementSubtype: MeasurementSubtype | null;
    unitOverride: string | null;
    v$: NestedValidations<AlertsFormData>;
  }>();

  const emit = defineEmits<{
    (eventName: 'update:modelValue', value: AlertsFormData): void;
    (eventName: 'field-edited', fieldPath: string): void;
  }>();

  const enabled = computed(() => !!selectedMeasurementSubtype);

  const unit = computed(() => {
    return unitOverride || selectedMeasurementSubtype?.default_unit || '';
  });

  const hasAnyThreshold = computed(() => {
    return modelValue.alarm_low !== null ||
           modelValue.alarm_high !== null ||
           modelValue.warning_low !== null ||
           modelValue.warning_high !== null;
  });

  function updateField(field: keyof AlertsFormData, value: unknown) {
    emit('update:modelValue', { ...modelValue, [field]: value });
    emit('field-edited', `measurement_point.${field}`);
  }
</script>

<style scoped>
  .alerts-tab {
    min-height: 300px;
  }
</style>
