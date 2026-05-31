<template>
  <CForm @submit.prevent="handleSubmit">
    <CTabs v-model:active-item-key="activeTab" variant="underline-border">
      <CTabList variant="underline-border" class="mb-4">
        <CTab item-key="measurement">
          <CIcon icon="cilSpeedometer" class="me-2" />
          Measurement
        </CTab>
        <CTab item-key="device" :disabled="!hasConfigurationMappings">
          <CIcon icon="cilCog" class="me-2" />
          Device Configuration
          <CBadge v-if="configErrors.length > 0" color="danger" class="ms-1">
            {{ configErrors.length }}
          </CBadge>
        </CTab>
        <CTab item-key="display" :disabled="!selectedMeasurementSubtype">
          <CIcon icon="cilChartLine" class="me-2" />
          Display Options
        </CTab>
      </CTabList>

      <CTabContent>
        <CTabPanel item-key="measurement">
          <MeasurementTab
            :model-value="measurementFormData"
            :segments="segments"
            :measurement-subtypes="availableMeasurementSubtypes"
            :register-template="editRegisterMapping.register_template"
            :v$="v$.measurement_point"
            @update:model-value="handleMeasurementFormUpdate"
            @field-edited="markFieldEdited" />
        </CTabPanel>

        <CTabPanel item-key="device">
          <DeviceConfigurationTab
            :model-value="configValues"
            :configuration-register-mappings="configurationRegisterMappings"
            :validation-errors="configErrors"
            :is-configuration-visible="isConfigurationVisible"
            @value-change="handleConfigValueChange" />
        </CTabPanel>

        <CTabPanel item-key="display">
          <DisplayOptionsTab
            :model-value="displayFormData"
            :selected-measurement-subtype="selectedMeasurementSubtype"
            :v$="v$.measurement_point"
            @update:model-value="Object.assign(displayFormData, $event)"
            @field-edited="markFieldEdited" />
        </CTabPanel>
      </CTabContent>
    </CTabs>

    <div class="d-flex justify-content-end gap-2 mt-4 pt-3 border-top">
      <CButton color="secondary" @click="$emit('cancel')" :disabled="processing">
        Cancel
      </CButton>
      <CButton type="submit" color="primary" :disabled="!canSubmit || processing">
        <CSpinner v-if="processing" component="span" size="sm" class="me-1" />
        <CIcon v-else icon="cilCheckCircle" class="me-1" />
        Save Changes
      </CButton>
    </div>
  </CForm>
</template>

<script lang="ts" setup>
  import { ref, computed, watch, reactive, toRef } from 'vue';
  import axios from 'axios';
  import { useVuelidate } from '@vuelidate/core';
  import { decimal, required, sameAs } from '@vuelidate/validators';
  import MeasurementTab from './tabs/MeasurementTab.vue';
  import DeviceConfigurationTab from './tabs/DeviceConfigurationTab.vue';
  import DisplayOptionsTab from './tabs/DisplayOptionsTab.vue';
  import { useApiCall } from '@/composables/useApi';
  import { useConfigurationValues } from '@/composables/useConfigurationValues';
  import { useRegisterVisibility } from '@/composables/useRegisterVisibility';
  import { useRegisterValidation } from '@/composables/useRegisterValidation';
  import useAuth from '@/composables/useAuth';
  import type { Segment } from '@/types/location';
  import { isDataCategory, isChartType, isValidChartTypeForValueType, type MeasurementPoint, type MeasurementSubtype, type ChartType } from '@/types/measurementPoint';
  import { isConfigurationCategory, type InterfaceWithMeasurementPoints, type MeasurementPointConfigResponse } from '@/types/plc';

  const {
    iface,
    segments,
    measurementSubtypes
  } = defineProps<{
    iface: InterfaceWithMeasurementPoints;
    segments: Segment[];
    measurementSubtypes: MeasurementSubtype[];
  }>();

  const emit = defineEmits<{
    (eventName: 'submit', updatedPoint: MeasurementPoint, siblingPoints: MeasurementPoint[]): void;
    (eventName: 'cancel'): void;
  }>();

  const { execute } = useApiCall();
  const { routePath } = useAuth();

  const activeTab = ref<string>('measurement');
  const processing = ref(false);

  const measurementRegisterMappings = computed(() => {
    return iface.register_mappings.filter((registerMapping) => {
      return isDataCategory(registerMapping.register_template.category);
    });
  });

  const originalRegisterMapping = computed(() => {
    if (measurementRegisterMappings.value.length === 0)
      throw new Error('No measurement register mappings found');

    const activeMapping = measurementRegisterMappings.value.find(
      (registerMapping) => registerMapping.measurement_point.active
    );
    if (activeMapping)
      return activeMapping;

    const configuredMapping = measurementRegisterMappings.value.find(
      (registerMapping) => !!registerMapping.measurement_point.measurement_subtype_id
    );
    return configuredMapping || measurementRegisterMappings.value[0];
  });

  const editRegisterMappingId = ref<MeasurementPoint['id'] | null>(null);
  const editRegisterMapping = computed(() => {
    if (editRegisterMappingId.value === null)
      return originalRegisterMapping.value;

    const mapping = measurementRegisterMappings.value.find(
      (rm) => rm.measurement_point.id === editRegisterMappingId.value
    );
    return mapping || originalRegisterMapping.value;
  });

  const availableMeasurementSubtypes = computed(() => {
    return measurementSubtypes.filter((subtype) => {
      return iface.data_categories.includes(subtype.data_category);
    });
  });

  const configurationRegisterMappings = computed(() => {
    return iface.register_mappings.filter((registerMapping) => {
      return isConfigurationCategory(registerMapping.register_template.category);
    });
  });

  const hasConfigurationMappings = computed(() => configurationRegisterMappings.value.length > 0);

  const measurementFormData = reactive({
    name: '',
    description: null as string | null,
    measurement_subtype_id: null as number | null,
    segment_id: null as number | null,
    factor_override: null as number | null,
    offset_override: null as number | null,
    active: false
  });

  const displayFormData = reactive({
    unit_override: null as string | null,
    chart_type_override: null as ChartType | null,
    color_override: null as string | null
  });

  const formData = computed(() => ({
    measurement_point: {
      ...measurementFormData,
      ...displayFormData
    }
  }));

  function handleMeasurementFormUpdate(newData: typeof measurementFormData) {
    Object.assign(measurementFormData, newData);
  }

  const {
    configValues,
    userEditedFields,
    initializeValues: initConfigValues,
    handleValueChange: handleConfigValueChange,
    markFieldEdited,
    resetEditTracking,
    getConfigurationUpdates
  } = useConfigurationValues(toRef(() => configurationRegisterMappings.value));

  const { isVisible: isConfigurationVisible } = useRegisterVisibility(
    toRef(() => configurationRegisterMappings.value),
    toRef(() => configValues)
  );

  const { errors: configErrors, validate: validateConfig } = useRegisterValidation(
    toRef(() => configurationRegisterMappings.value),
    toRef(() => configValues),
    isConfigurationVisible
  );

  const selectedMeasurementSubtype = computed(() => {
    if (!measurementFormData.measurement_subtype_id)
      return null;

    return measurementSubtypes.find(
      (subtype) => subtype.id === measurementFormData.measurement_subtype_id
    ) || null;
  });

  function isValidHexColor(value: string | null): boolean {
    if (!value)
      return true;

    return /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(value);
  }

  const rules = computed(() => ({
    measurement_point: {
      name: { required },
      description: {},
      unit_override: {},
      chart_type_override: {
        isChartType: {
          $validator: (value: string | null) => !value || isChartType(value),
          $message: 'Please select a valid chart type'
        },
        isCompatibleWithValueType: {
          $validator: (value: string | null) => {
            if (!value || !isChartType(value)) return true;
            const vt = selectedMeasurementSubtype.value?.value_type;
            if (!vt) return true;
            return isValidChartTypeForValueType(value, vt);
          },
          $message: 'This chart type is not compatible with the selected measurement type'
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
      active: { required, sameAs: sameAs(true) || sameAs(false) },
      measurement_subtype_id: { required },
      segment_id: {}
    }
  }));

  const v$ = useVuelidate(rules, formData);

  const canSubmit = computed(() => {
    return userEditedFields.value.size > 0 && configErrors.value.length === 0;
  });

  function loadMeasurementPoint(registerMapping: typeof originalRegisterMapping.value) {
    const measurementPoint = registerMapping.measurement_point;

    Object.assign(measurementFormData, {
      name: measurementPoint.name,
      description: measurementPoint.description,
      measurement_subtype_id: measurementPoint.measurement_subtype_id,
      segment_id: measurementPoint.segment_id,
      factor_override: measurementPoint.factor_override,
      offset_override: measurementPoint.offset_override,
      active: measurementPoint.active
    });

    Object.assign(displayFormData, {
      unit_override: measurementPoint.unit_override,
      chart_type_override: measurementPoint.chart_type_override,
      color_override: measurementPoint.color_override
    });
  }

  async function handleSubmit() {
    const isValid = await v$.value.$validate();
    if (!isValid || !canSubmit.value) {
      const firstInvalidElement = document.querySelector('.is-invalid');
      firstInvalidElement?.scrollIntoView({ behavior: 'smooth', block: 'center' });
      return;
    }

    processing.value = true;

    const url = routePath('measurement_points_update', { id: editRegisterMapping.value.measurement_point.id });
    const { success, data } = await execute<MeasurementPointConfigResponse>(
      () => axios.put(url, {
        ...formData.value,
        configuration_updates: getConfigurationUpdates()
      }),
      {
        showSuccessToast: true,
        successMessage: `Interface ${iface.name} updated successfully`,
        showErrorToast: true,
        errorTitle: 'Error'
      }
    );

    if (success) {
      emit('submit', data.measurement_point, data.sibling_measurement_points);
      resetEditTracking();
    }

    processing.value = false;
  }

  watch(
    originalRegisterMapping,
    (newValue) => {
      if (!editRegisterMappingId.value) {
        editRegisterMappingId.value = newValue.measurement_point.id;
        resetEditTracking();
        loadMeasurementPoint(newValue);
        initConfigValues();
      }
    },
    { immediate: true }
  );

  watch(
    () => measurementFormData.measurement_subtype_id,
    (newValue, oldValue) => {
      if (newValue === oldValue)
        return;

      const newMeasurementSubtype = newValue
        ? measurementSubtypes.find((s) => s.id === newValue)
        : null;
      if (!newMeasurementSubtype) {
        editRegisterMappingId.value = originalRegisterMapping.value.measurement_point.id;
        resetEditTracking();
        loadMeasurementPoint(originalRegisterMapping.value);
        initConfigValues();
        return;
      }

      // Clear chart type override if incompatible with the new value type
      if (
        displayFormData.chart_type_override &&
        isChartType(displayFormData.chart_type_override) &&
        !isValidChartTypeForValueType(displayFormData.chart_type_override, newMeasurementSubtype.value_type)
      ) {
        displayFormData.chart_type_override = null;
      }

      const newActiveMapping = measurementRegisterMappings.value.find(
        (registerMapping) => registerMapping.register_template.category === newMeasurementSubtype.data_category
      );

      if (newActiveMapping && newActiveMapping.measurement_point.id !== editRegisterMappingId.value) {
        editRegisterMappingId.value = newActiveMapping.measurement_point.id;

        const measurementPoint = newActiveMapping.measurement_point;
        if (!userEditedFields.value.has('measurement_point.name'))
          measurementFormData.name = measurementPoint.name;

        if (!userEditedFields.value.has('measurement_point.description'))
          measurementFormData.description = measurementPoint.description;

        if (!userEditedFields.value.has('measurement_point.segment_id'))
          measurementFormData.segment_id = measurementPoint.segment_id;

        if (!userEditedFields.value.has('measurement_point.chart_type_override'))
          displayFormData.chart_type_override = measurementPoint.chart_type_override;

        if (!userEditedFields.value.has('measurement_point.color_override'))
          displayFormData.color_override = measurementPoint.color_override;

        initConfigValues();
      }
    }
  );
</script>

<style scoped>
  :deep(.nav-underline-border) {
    border-bottom: 1px solid #dee2e6;
  }

  :deep(.nav-underline-border .nav-link) {
    border-bottom: 2px solid transparent;
    margin-bottom: -1px;
    padding: 0.75rem 1rem;
    color: #6c757d;
  }

  :deep(.nav-underline-border .nav-link:hover) {
    border-color: #dee2e6;
    color: #495057;
  }

  :deep(.nav-underline-border .nav-link.active) {
    border-color: var(--cui-primary);
    color: var(--cui-primary);
  }

  :deep(.nav-underline-border .nav-link:disabled) {
    color: #adb5bd;
    cursor: not-allowed;
  }
</style>
