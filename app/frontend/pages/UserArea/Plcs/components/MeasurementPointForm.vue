<template>
  <CForm @submit.prevent="handleSubmit">
    <div class="row g-4">
      <!-- Left Column: Basic Info -->
      <div class="col-md-6">
        <h6 class="text-muted mb-3">Device Information</h6>

        <!-- Device Name -->
        <div class="mb-3">
          <CFormLabel class="fw-semibold">Device Name <span class="text-danger">*</span></CFormLabel>
          <CFormInput
            v-model="formData.measurement_point.name"
            @input="markFieldEdited('measurement_point.name')"
            :invalid="v$.measurement_point.name.$error"
            placeholder="e.g., Main Water Pump, Temperature Sensor 1"
            required />
          <CFormFeedback v-if="v$.measurement_point.name.$error" invalid>
            {{ v$.measurement_point.name.$errors[0].$message }}
          </CFormFeedback>
          <div class="form-text">
            Give this device a descriptive name that identifies its purpose or location.
          </div>
        </div>

        <!-- Description -->
        <div class="mb-3">
          <CFormLabel class="fw-semibold">Description</CFormLabel>
          <CFormTextarea
            v-model="formData.measurement_point.description"
            @input="markFieldEdited('measurement_point.description')"
            rows="2"
            placeholder="Optional notes about this device..." />
          <CFormFeedback v-if="v$.measurement_point.description.$error" invalid>
            {{ v$.measurement_point.description.$errors[0].$message }}
          </CFormFeedback>
        </div>

        <!-- Measurement Type Selection -->
        <div class="mb-3">
          <CFormLabel class="fw-semibold">Measurement Type <span class="text-danger">*</span></CFormLabel>
          <CFormSelect
            v-model="formData.measurement_point.measurement_subtype_id"
            :invalid="v$.measurement_point.measurement_subtype_id.$error"
            required>
            <option value="">-- Select Type --</option>
            <optgroup
              v-for="typeGroup in groupedSubtypes"
              :key="typeGroup.type"
              :label="typeGroup.type">
              <option
                v-for="subtype in typeGroup.subtypes"
                :key="subtype.id"
                :value="subtype.id">
                {{ subtype.name }} ({{ subtype.default_unit }})
              </option>
            </optgroup>
          </CFormSelect>
          <CFormFeedback v-if="v$.measurement_point.measurement_subtype_id.$error" invalid>
            {{ v$.measurement_point.measurement_subtype_id.$errors[0].$message }}
          </CFormFeedback>
          <div class="form-text">
            Select the type of measurement this device provides.
          </div>
        </div>

        <!-- Segment Assignment -->
        <div class="mb-3">
          <CFormLabel class="fw-semibold">Segment</CFormLabel>
          <CFormSelect
            v-model="formData.measurement_point.segment_id"
            @change="markFieldEdited('measurement_point.segment_id')">
            <option value="">-- No Segment --</option>
            <option v-for="segment in segments" :key="segment.id" :value="segment.id">
              {{ segment.name }}
            </option>
          </CFormSelect>
          <div class="form-text">
            Optionally assign this device to a segment for organization.
          </div>
          <CFormFeedback v-if="v$.measurement_point.segment_id.$error" invalid>
            {{ v$.measurement_point.segment_id.$errors[0].$message }}
          </CFormFeedback>
        </div>
      </div>

      <!-- Right Column: Display Options -->
      <div v-show="formData.measurement_point.measurement_subtype_id" class="col-md-6">
        <h6 class="text-muted mb-3">Display Options</h6>

        <!-- Unit Override -->
        <div class="mb-3">
          <CFormLabel class="fw-semibold">Unit</CFormLabel>
          <div class="input-group">
            <CFormInput
              v-model="formData.measurement_point.unit_override"
              @input="markFieldEdited('measurement_point.unit_override')"
              :placeholder="defaultUnit || 'Enter unit'" />
            <span v-if="defaultUnit && !formData.measurement_point.unit_override" class="input-group-text">
              Default: {{ defaultUnit }}
            </span>
          </div>
          <div class="form-text">
            Override the default unit if needed (e.g., °F instead of °C).
          </div>
          <CFormFeedback v-if="v$.measurement_point.unit_override.$error" invalid>
            {{ v$.measurement_point.unit_override.$errors[0].$message }}
          </CFormFeedback>
        </div>

        <!-- Chart Type -->
        <div class="mb-3">
          <CFormLabel class="fw-semibold">Chart Type</CFormLabel>
          <CFormSelect
            v-model="formData.measurement_point.chart_type_override"
            @change="markFieldEdited('measurement_point.chart_type_override')">
            <option value="">Default ({{ defaultChartType || 'Auto' }})</option>
            <option value="line">Line</option>
            <option value="spline">Spline (Curved)</option>
            <option value="areaspline">Area Spline</option>
            <option value="bar">Bar</option>
            <option value="state">State (On/Off)</option>
          </CFormSelect>
          <div class="form-text">
            Choose how this measurement is displayed in charts.
          </div>
          <CFormFeedback v-if="v$.measurement_point.chart_type_override.$error" invalid>
            {{ v$.measurement_point.chart_type_override.$errors[0].$message }}
          </CFormFeedback>
        </div>

        <!-- Color Picker -->
        <div class="mb-3">
          <CFormLabel class="fw-semibold">Chart Color</CFormLabel>
          <div class="d-flex align-items-center gap-2">
            <CFormInput
              v-model="formData.measurement_point.color_override"
              @input="markFieldEdited('measurement_point.color_override')"
              type="color"
              :value="formData.measurement_point.color_override || defaultColor || '#3B82F6'" />
            <CFormInput
              v-model="formData.measurement_point.color_override"
              @input="markFieldEdited('measurement_point.color_override')"
              :placeholder="defaultColor || '#3B82F6'"
              pattern="^#[0-9A-Fa-f]{6}$"
              style="max-width: 120px;" />
            <CButton
              v-if="formData.measurement_point.color_override"
              color="light"
              size="sm"
              @click="formData.measurement_point.color_override = null">
              Reset
            </CButton>
          </div>
          <div class="form-text">
            Choose a custom color for this measurement in charts.
          </div>
          <CFormFeedback v-if="v$.measurement_point.color_override.$error" invalid>
            {{ v$.measurement_point.color_override.$errors[0].$message }}
          </CFormFeedback>
        </div>
      </div>
    </div>

    <!-- Form Actions -->
    <div class="d-flex justify-content-end gap-2 mt-4">
      <CButton color="secondary" @click="$emit('cancel')">
        Cancel
      </CButton>
      <CButton type="submit" color="primary" :disabled="processing">
        <CSpinner v-if="processing" size="sm" class="me-2" />
        Save Configuration
      </CButton>
    </div>
  </CForm>
</template>

<script lang="ts" setup>
  import { ref, computed, watch } from 'vue';
  import axios from 'axios';
  import { useForm } from '@inertiajs/vue3';
  import { useVuelidate } from '@vuelidate/core';
  import { decimal, required } from '@vuelidate/validators';
  import { useApiCall } from '@/composables/useApi';
  import { ROUTES } from '@/types/permissions';
  import type { Segment } from '@/types/location';
  import { isChartType, type MeasurementPoint, type MeasurementSubtype } from '@/types/measurementPoint';
  import type { InterfaceWithMeasurementPoints } from '@/types/plc';
  import type { MeasurementPointFormData } from '../types';

  const props = defineProps<{
    interface: InterfaceWithMeasurementPoints;
    segments: Segment[];
    measurementSubtypes: MeasurementSubtype[];
  }>();

  const emit = defineEmits<{
    (e: 'submit', iface: InterfaceWithMeasurementPoints): void;
    (e: 'cancel'): void;
  }>();

  const { execute } = useApiCall();

  const userEditedFields = ref<Set<string>>(new Set());
  const processing = ref(false);

  const activeRegisterMapping = computed(() => {
    if (props.interface.register_mappings.length === 0)
      return null;

    const mp = props.interface.register_mappings.find((registerMapping) => {
      return registerMapping.measurement_point.active;
    });
    return mp || props.interface.register_mappings[0];
  });

  const groupedSubtypes = computed(() => {
    const groups: Record<string, { type: string; subtypes: MeasurementSubtype[] }> = {};

    props.measurementSubtypes.forEach(subtype => {
      if (!props.interface.data_categories.includes(subtype.data_category))
        return;

      const typeName = subtype.measurement_type.name;
      if (!groups[typeName]) {
        groups[typeName] = { type: typeName, subtypes: [] };
      }
      groups[typeName].subtypes.push(subtype);
    });

    return Object.values(groups);
  });

  const selectedSubtype = computed(() => {
    return props.measurementSubtypes.find((s) => s.id == formData.measurement_point.measurement_subtype_id);
  });

  const defaultUnit = computed(() => selectedSubtype.value?.default_unit || null);
  const defaultChartType = computed(() => selectedSubtype.value?.default_chart_type || null);
  const defaultColor = computed(() => selectedSubtype.value?.default_color || null);

  function initFormData(registerMapping: InterfaceWithMeasurementPoints['register_mappings'][number] | null) {
    return {
      measurement_point: {
        id: registerMapping?.measurement_point.id || null,
        name: registerMapping?.measurement_point.name || '',
        description: registerMapping?.measurement_point.description || '',
        unit_override: registerMapping?.measurement_point.unit_override || null,
        chart_type_override: registerMapping?.measurement_point.chart_type_override || null,
        color_override: registerMapping?.measurement_point.color_override || null,
        factor_override: registerMapping?.measurement_point.factor_override || null,
        offset_override: registerMapping?.measurement_point.offset_override || null,
        alarm_low: registerMapping?.measurement_point.alarm_low || null,
        alarm_high: registerMapping?.measurement_point.alarm_high || null,
        warning_low: registerMapping?.measurement_point.warning_low || null,
        warning_high: registerMapping?.measurement_point.warning_high || null,
        active: registerMapping?.measurement_point.active || false,
        measurement_subtype_id: registerMapping?.measurement_point.measurement_subtype_id || null,
        segment_id: registerMapping?.measurement_point.segment_id || null
      }
    };
  }

  const formData = useForm(initFormData(activeRegisterMapping.value));

  function markFieldEdited(fieldPath: string) {
    userEditedFields.value.add(fieldPath);
  }

  function resetEditTracking() {
    userEditedFields.value.clear();
  }

  function mergeFormData(registerMapping: InterfaceWithMeasurementPoints['register_mappings'][number] | null) {
    const freshData = initFormData(registerMapping);

    const mpFields = Object.keys(freshData.measurement_point) as Array<keyof typeof freshData.measurement_point>;
    for (const field of mpFields) {
      if (field === 'measurement_subtype_id')
        continue;

      const fieldPath = `measurement_point.${field}`;
      if (!userEditedFields.value.has(fieldPath)) {
        (formData.measurement_point as any)[field] = freshData.measurement_point[field];
      }
    }
  }

  function isValidHexColor(value: string | null) {
    if (!value)
      return true;
    return /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(value);
  }

  function rules() {
    return {
      measurement_point: {
        id: { required },
        name: { required },
        description: {},
        unit_override: {},
        chart_type_override: {
          isChartType: {
            $validator: (value: string | null) => !value || isChartType(value),
            $message: 'Please select a valid chart type'
          }
        },
        color_override: {
          isValidHexColor: {
            $validator: (value: string | null) => !value || isValidHexColor(value),
            $message: 'Please enter a valid hex color (e.g., #FF0000)'
          }
        },
        factor_override: { decimal },
        offset_override: { decimal },
        alarm_low: { decimal },
        alarm_high: { decimal },
        warning_low: { decimal },
        warning_high: { decimal },
        measurement_subtype_id: { required },
        segment_id: {}
      }
    };
  }

  const v$ = useVuelidate(rules, formData);

  async function handleSubmit() {
    const isValid = await v$.value.$validate();
    if (!isValid) {
      const firstInvalidElement = document.querySelector('.is-invalid');
      firstInvalidElement?.scrollIntoView({
        behavior: 'smooth',
        block: 'center'
      });
      return;
    }

    processing.value = true;

    const url = ROUTES.measurement_points_update.path.replace(':id', String(formData.measurement_point.id));
    formData.measurement_point.active = true;
    const { success, data } = await execute<MeasurementPoint>(
      () => axios.put(url, { ...formData }),
      {
        showSuccessToast: true,
        successMessage: `Interface ${props.interface.name} updated successfully`,
        showErrorToast: true,
        errorTitle: 'Error'
      }
    );

    if (success) {
      emit('submit', props.interface);
      resetEditTracking();
    }

    processing.value = false;
  }

  watch(
    activeRegisterMapping,
    (newValue, oldValue) => {
      if (newValue && newValue !== oldValue) {
        resetEditTracking();
        Object.assign(formData, initFormData(newValue));
      }
    },
    { immediate: true }
  );

  watch(
    () => formData.measurement_point.measurement_subtype_id,
    (newValue, oldValue) => {
      if (newValue === oldValue)
        return;

      const newActiveRegisterMapping = props.interface.register_mappings.find((registerMapping) => {
        return registerMapping.category === selectedSubtype.value?.data_category;
      });
      if (newActiveRegisterMapping)
        mergeFormData(newActiveRegisterMapping);
    }
  );
</script>

<style scoped>
  .form-control-color {
    padding: 0.25rem;
    cursor: pointer;
  }
</style>
