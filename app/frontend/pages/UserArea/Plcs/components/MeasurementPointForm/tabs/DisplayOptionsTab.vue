<template>
  <div class="display-options-tab py-3">
    <div v-if="!enabled" class="text-center py-5 text-muted">
      <CIcon icon="cilChartLine" size="3xl" class="mb-3" />
      <p>Select a measurement type first to configure display options.</p>
    </div>

    <div v-else class="row g-4">
      <div class="col-md-6">
        <div class="mb-3">
          <CFormLabel class="fw-semibold">Unit</CFormLabel>
          <div class="input-group">
            <CFormInput
              :model-value="modelValue.unit_override"
              @update:model-value="updateField('unit_override', $event)"
              :placeholder="defaultUnit || 'Enter unit'" />
            <span v-if="defaultUnit && !modelValue.unit_override" class="input-group-text">
              Default: {{ defaultUnit }}
            </span>
          </div>
          <div class="form-text">
            Override the default unit if needed (e.g., °F instead of °C).
          </div>
        </div>

        <div class="mb-3">
          <CFormLabel class="fw-semibold">Chart Type</CFormLabel>
          <CFormSelect
            :model-value="modelValue.chart_type_override || ''"
            @update:model-value="updateField('chart_type_override', $event || null)"
            :invalid="v$.chart_type_override.$error">
            <option value="">-- Use Default ({{ chartTypeLabel(defaultChartType) }}) --</option>
            <option
              v-for="type in allowedChartTypes"
              :key="type"
              :value="type">
              {{ chartTypeLabel(type) }}
            </option>
          </CFormSelect>
          <CFormFeedback v-if="v$.chart_type_override.$error" invalid>
            {{ v$.chart_type_override.$errors[0].$message }}
          </CFormFeedback>
          <div class="form-text">
            Choose how this data should be visualized in charts.
          </div>
        </div>
      </div>

      <div class="col-md-6">
        <div class="mb-3">
          <CFormLabel class="fw-semibold">Color</CFormLabel>
          <div class="d-flex gap-2">
            <input
              type="color"
              class="form-control form-control-color"
              :value="modelValue.color_override || defaultColor || '#0d6efd'"
              @input="updateField('color_override', ($event.target as HTMLInputElement).value)" />
            <CFormInput
              :model-value="modelValue.color_override"
              @update:model-value="updateField('color_override', $event)"
              :invalid="v$.color_override.$error"
              :placeholder="defaultColor || '#0d6efd'"
              class="font-monospace" />
            <CButton
              v-if="modelValue.color_override"
              variant="outline"
              color="secondary"
              @click="updateField('color_override', null)">
              Reset
            </CButton>
          </div>
          <CFormFeedback v-if="v$.color_override.$error" invalid>
            {{ v$.color_override.$errors[0].$message }}
          </CFormFeedback>
          <div class="form-text">
            Customize the color used in charts and displays.
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import type { NestedValidations } from '@vuelidate/core';
  import {
    CHART_TYPES_BY_VALUE_TYPE,
    type ChartType,
    type MeasurementSubtype,
  } from '@/types/measurementPoint';

  type DisplayFormData = {
    unit_override: string | null;
    chart_type_override: ChartType | null;
    color_override: string | null;
  };

  const {
    modelValue,
    selectedMeasurementSubtype,
    v$
  } = defineProps<{
    modelValue: DisplayFormData;
    selectedMeasurementSubtype: MeasurementSubtype | null;
    v$: NestedValidations<DisplayFormData>;
  }>();

  const emit = defineEmits<{
    (eventName: 'update:modelValue', value: DisplayFormData): void;
    (eventName: 'field-edited', fieldPath: string): void;
  }>();

  const enabled = computed(() => !!selectedMeasurementSubtype);
  const defaultUnit = computed(() => selectedMeasurementSubtype?.default_unit || null);
  const defaultChartType = computed(() => selectedMeasurementSubtype?.default_chart_type || 'line');
  const defaultColor = computed(() => selectedMeasurementSubtype?.default_color || null);

  const allowedChartTypes = computed<readonly ChartType[]>(() => {
    if (!selectedMeasurementSubtype)
      return [];

    return CHART_TYPES_BY_VALUE_TYPE[selectedMeasurementSubtype.value_type];
  });

  const CHART_TYPE_LABELS: Record<ChartType, string> = {
    line: 'Line',
    area: 'Area',
    bar: 'Bar',
    step: 'Step (Digital Signal)',
    rangeBar: 'Range Bar (Timeline)',
  };

  function chartTypeLabel(type: ChartType): string {
    return CHART_TYPE_LABELS[type] ?? type;
  }

  function updateField(field: keyof DisplayFormData, value: unknown) {
    emit('update:modelValue', { ...modelValue, [field]: value });
    emit('field-edited', `measurement_point.${field}`);
  }
</script>

<style scoped>
  .display-options-tab {
    min-height: 300px;
  }

  .form-control-color {
    width: 60px;
    padding: 0.25rem;
    cursor: pointer;
  }
</style>
