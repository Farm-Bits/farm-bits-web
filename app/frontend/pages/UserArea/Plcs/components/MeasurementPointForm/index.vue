<template>
  <CForm @submit.prevent="handleSubmit">
    <!-- Tabs Navigation -->
    <CTabs v-model:active-item-key="activeTab" variant="underline-border">
      <CTabList variant="underline-border" class="mb-4">
        <CTab item-key="measurement">
          <CIcon icon="cilSpeedometer" class="me-2" />
          Measurement
        </CTab>
        <CTab item-key="device" :disabled="!hasConfigurationMappings">
          <CIcon icon="cilCog" class="me-2" />
          Device Configuration
          <CBadge v-if="configurationErrors.length > 0" color="danger" class="ms-1">
            {{ configurationErrors.length }}
          </CBadge>
        </CTab>
        <CTab item-key="display" :disabled="!formData.measurement_point.measurement_subtype_id">
          <CIcon icon="cilChartLine" class="me-2" />
          Display Options
        </CTab>
        <CTab item-key="alerts" :disabled="!formData.measurement_point.measurement_subtype_id">
          <CIcon icon="cilBell" class="me-2" />
          Alerts
        </CTab>
      </CTabList>

      <CTabContent>
        <!-- Tab 1: Measurement Configuration -->
        <CTabPanel item-key="measurement" class="py-3">
          <div class="row g-4">
            <div class="col-md-6">
              <!-- Device Name -->
              <div class="mb-3">
                <CFormLabel class="fw-semibold">
                  Device Name <span class="text-danger">*</span>
                </CFormLabel>
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
              </div>

              <!-- Measurement Type Selection -->
              <div class="mb-3">
                <CFormLabel class="fw-semibold">
                  Measurement Type <span class="text-danger">*</span>
                </CFormLabel>
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
            </div>

            <div class="col-md-6">
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
              </div>

              <!-- Factor Override -->
              <div class="mb-3">
                <CFormLabel class="fw-semibold">Factor Override</CFormLabel>
                <CFormInput
                  v-model.number="formData.measurement_point.factor_override"
                  @input="markFieldEdited('measurement_point.factor_override')"
                  type="number"
                  step="any"
                  :placeholder="defaultFactor ? `Default: ${defaultFactor}` : 'Enter factor'" />
                <div class="form-text">
                  Value transformation: scaled = (raw × factor) + offset
                </div>
              </div>

              <!-- Offset Override -->
              <div class="mb-3">
                <CFormLabel class="fw-semibold">Offset Override</CFormLabel>
                <CFormInput
                  v-model.number="formData.measurement_point.offset_override"
                  @input="markFieldEdited('measurement_point.offset_override')"
                  type="number"
                  step="any"
                  :placeholder="defaultOffset ? `Default: ${defaultOffset}` : 'Enter offset'" />
                <div class="form-text">
                  Value transformation: scaled = (raw × factor) + offset
                </div>
              </div>
            </div>
          </div>
        </CTabPanel>

        <!-- Tab 2: Device Configuration -->
        <CTabPanel item-key="device" class="py-3">
          <div v-if="!hasConfigurationMappings" class="text-center py-5 text-muted">
            <CIcon icon="cilCog" size="3xl" class="mb-3" />
            <p>No device configuration options available for this interface.</p>
          </div>

          <div v-else>
            <!-- Configuration Errors Alert -->
            <CAlert v-if="configurationErrors.length > 0" color="danger" class="mb-4">
              <strong>Configuration Errors:</strong>
              <ul class="mb-0 mt-2">
                <li v-for="(error, index) in configurationErrors" :key="index">
                  {{ error }}
                </li>
              </ul>
            </CAlert>

            <!-- Grouped Configuration Settings -->
            <div v-for="group in configurationGroups" :key="group.name" class="mb-4">
              <h6 class="text-muted border-bottom pb-2 mb-3">
                <CIcon :icon="getGroupIcon(group.name)" class="me-2" />
                {{ formatGroupName(group.name) }}
              </h6>

              <div class="row g-3">
                <div
                  v-for="mapping in group.mappings"
                  :key="mapping.register_template.id"
                  :class="getConfigFieldClass(mapping)"
                  v-show="isConfigurationVisible(mapping)">
                  <ConfigurationField
                    :mapping="mapping"
                    :configValues="configValues"
                    :allMappings="configurationRegisterMappings"
                    @update="handleConfigValueChange" />
                </div>
              </div>
            </div>
          </div>
        </CTabPanel>

        <!-- Tab 3: Display Options -->
        <CTabPanel item-key="display" class="py-3">
          <div v-if="!formData.measurement_point.measurement_subtype_id" class="text-center py-5 text-muted">
            <CIcon icon="cilChartLine" size="3xl" class="mb-3" />
            <p>Select a measurement type first to configure display options.</p>
          </div>

          <div v-else class="row g-4">
            <div class="col-md-6">
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
              </div>
            </div>

            <div class="col-md-6">
              <!-- Color Picker -->
              <div class="mb-3">
                <CFormLabel class="fw-semibold">Chart Color</CFormLabel>
                <div class="d-flex align-items-center gap-2">
                  <CFormInput
                    v-model="formData.measurement_point.color_override"
                    @input="markFieldEdited('measurement_point.color_override')"
                    type="color"
                    class="form-control-color"
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
              </div>
            </div>
          </div>
        </CTabPanel>

        <!-- Tab 4: Alert Configuration -->
        <CTabPanel item-key="alerts" class="py-3">
          <div v-if="!formData.measurement_point.measurement_subtype_id" class="text-center py-5 text-muted">
            <CIcon icon="cilBell" size="3xl" class="mb-3" />
            <p>Select a measurement type first to configure alerts.</p>
          </div>

          <div v-else>
            <p class="text-muted mb-4">
              Configure thresholds to receive alerts when values exceed normal ranges.
              Warning alerts are informational; Alarm alerts require immediate attention.
            </p>

            <div class="row g-4">
              <!-- Warning Thresholds -->
              <div class="col-md-6">
                <CCard class="border-warning">
                  <CCardHeader class="bg-warning bg-opacity-10 border-warning">
                    <CIcon icon="cilWarning" class="me-2 text-warning" />
                    <strong>Warning Thresholds</strong>
                  </CCardHeader>
                  <CCardBody>
                    <div class="mb-3">
                      <CFormLabel>Low Warning</CFormLabel>
                      <div class="input-group">
                        <CFormInput
                          v-model.number="formData.measurement_point.warning_low"
                          @input="markFieldEdited('measurement_point.warning_low')"
                          type="number"
                          step="any"
                          placeholder="Enter value"
                          :invalid="warningLowError" />
                        <span class="input-group-text">{{ effectiveUnit }}</span>
                      </div>
                      <CFormFeedback v-if="warningLowError" invalid class="d-block">
                        Warning low must be less than warning high
                      </CFormFeedback>
                    </div>
                    <div class="mb-0">
                      <CFormLabel>High Warning</CFormLabel>
                      <div class="input-group">
                        <CFormInput
                          v-model.number="formData.measurement_point.warning_high"
                          @input="markFieldEdited('measurement_point.warning_high')"
                          type="number"
                          step="any"
                          placeholder="Enter value"
                          :invalid="warningHighError" />
                        <span class="input-group-text">{{ effectiveUnit }}</span>
                      </div>
                      <CFormFeedback v-if="warningHighError" invalid class="d-block">
                        Warning high must be greater than warning low
                      </CFormFeedback>
                    </div>
                  </CCardBody>
                </CCard>
              </div>

              <!-- Alarm Thresholds -->
              <div class="col-md-6">
                <CCard class="border-danger">
                  <CCardHeader class="bg-danger bg-opacity-10 border-danger">
                    <CIcon icon="cilBellExclamation" class="me-2 text-danger" />
                    <strong>Alarm Thresholds</strong>
                  </CCardHeader>
                  <CCardBody>
                    <div class="mb-3">
                      <CFormLabel>Low Alarm</CFormLabel>
                      <div class="input-group">
                        <CFormInput
                          v-model.number="formData.measurement_point.alarm_low"
                          @input="markFieldEdited('measurement_point.alarm_low')"
                          type="number"
                          step="any"
                          placeholder="Enter value"
                          :invalid="alarmLowError" />
                        <span class="input-group-text">{{ effectiveUnit }}</span>
                      </div>
                      <CFormFeedback v-if="alarmLowError" invalid class="d-block">
                        {{ alarmLowErrorMessage }}
                      </CFormFeedback>
                    </div>
                    <div class="mb-0">
                      <CFormLabel>High Alarm</CFormLabel>
                      <div class="input-group">
                        <CFormInput
                          v-model.number="formData.measurement_point.alarm_high"
                          @input="markFieldEdited('measurement_point.alarm_high')"
                          type="number"
                          step="any"
                          placeholder="Enter value"
                          :invalid="alarmHighError" />
                        <span class="input-group-text">{{ effectiveUnit }}</span>
                      </div>
                      <CFormFeedback v-if="alarmHighError" invalid class="d-block">
                        {{ alarmHighErrorMessage }}
                      </CFormFeedback>
                    </div>
                  </CCardBody>
                </CCard>
              </div>
            </div>

            <!-- Threshold Visualization -->
            <div class="mt-4">
              <CCard>
                <CCardBody>
                  <h6 class="mb-3">Threshold Overview</h6>
                  <ThresholdVisualization
                    :alarmLow="formData.measurement_point.alarm_low"
                    :warningLow="formData.measurement_point.warning_low"
                    :warningHigh="formData.measurement_point.warning_high"
                    :alarmHigh="formData.measurement_point.alarm_high"
                    :unit="effectiveUnit" />
                </CCardBody>
              </CCard>
            </div>
          </div>
        </CTabPanel>
      </CTabContent>
    </CTabs>

    <!-- Form Actions -->
    <div class="d-flex justify-content-between align-items-center mt-4 pt-3 border-top">
      <div class="text-muted small">
        <span v-if="hasUnsavedChanges" class="text-warning">
          <CIcon icon="cilWarning" class="me-1" />
          Unsaved changes
        </span>
      </div>
      <div class="d-flex gap-2">
        <CButton color="secondary" variant="outline" @click="$emit('cancel')">
          Cancel
        </CButton>
        <CButton type="submit" color="primary" :disabled="processing || !canSubmit">
          <CSpinner v-if="processing" size="sm" class="me-2" />
          Save Configuration
        </CButton>
      </div>
    </div>
  </CForm>
</template>

<script lang="ts" setup>
  import { ref, computed, watch, reactive } from 'vue';
  import axios from 'axios';
  import { useForm } from '@inertiajs/vue3';
  import { useVuelidate } from '@vuelidate/core';
  import { decimal, required } from '@vuelidate/validators';
  import { useApiCall } from '@/composables/useApi';
  import { ROUTES } from '@/types/permissions';
  import type { Segment } from '@/types/location';
  import {
    isChartType,
    isDataCategory,
    type MeasurementPoint,
    type MeasurementSubtype,
    type MeasurementType
  } from '@/types/measurementPoint';
  import {
    isConfigurationCategory,
    type InterfaceWithMeasurementPoints,
    type RegisterMapping,
    type RegisterTemplate
  } from '@/types/plc';
  import ConfigurationField, { type ConfigValues } from './ConfigurationField.vue';
  import ThresholdVisualization from './ThresholdVisualization.vue';

  type ConfigurationGroup = {
    name: string;
    mappings: RegisterMapping[];
  }

  const props = defineProps<{
    interface: InterfaceWithMeasurementPoints;
    segments: Segment[];
    measurementSubtypes: MeasurementSubtype[];
  }>();

  const emit = defineEmits<{
    (
      e: 'submit',
      updatedMeasurementPoint: MeasurementPoint,
      siblingMeasurementPoints: MeasurementPoint[]
    ): void;
    (e: 'cancel'): void;
  }>();

  const { execute } = useApiCall();

  const activeTab = ref<'measurement' | 'device' | 'display' | 'alerts'>('measurement');
  const userEditedFields = ref<Set<string>>(new Set());
  const processing = ref(false);
  const configValues = reactive<ConfigValues>({});
  const configurationErrors = ref<string[]>([]);

  const activeRegisterMapping = computed(() => {
    const measurementMappings = props.interface.register_mappings.filter(
      (m) => isDataCategory(m.register_template.category)
    );
    if (measurementMappings.length === 0)
      return null;

    const active = measurementMappings.find((m) => m.measurement_point.active);
    return active || measurementMappings[0];
  });

  const configurationRegisterMappings = computed(() => {
    return props.interface.register_mappings.filter(
      (m) => isConfigurationCategory(m.register_template.category)
    );
  });

  const hasConfigurationMappings = computed(() => {
    return configurationRegisterMappings.value.length > 0;
  });

  const configurationGroups = computed<ConfigurationGroup[]>(() => {
    const mappings = configurationRegisterMappings.value;
    const groups: Record<NonNullable<RegisterTemplate['group_name']>, RegisterMapping[]> = {};

    mappings.forEach((mapping) => {
      const groupName = mapping.register_template.group_name || 'general';
      if (!groups[groupName])
        groups[groupName] = [];

      groups[groupName].push(mapping);
    });

    const sortedGroupNames = Object.keys(groups).sort((a, b) => {
      if (a === 'general')
        return -1;

      if (b === 'general')
        return 1;

      return a.localeCompare(b);
    });

    return sortedGroupNames.map((name) => ({
      name,
      mappings: groups[name].sort((a, b) => a.position - b.position)
    }));
  });

  const groupedSubtypes = computed(() => {
    const groups: Record<
      MeasurementType['name'],
      { type: MeasurementType['name']; subtypes: MeasurementSubtype[] }
    > = {};

    props.measurementSubtypes.forEach((subtype) => {
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
    return props.measurementSubtypes.find(
      (s) => s.id.toString() === formData.measurement_point.measurement_subtype_id?.toString()
    );
  });

  const defaultUnit = computed(() => selectedSubtype.value?.default_unit || null);
  const defaultChartType = computed(() => selectedSubtype.value?.default_chart_type || null);
  const defaultColor = computed(() => selectedSubtype.value?.default_color || null);
  const defaultFactor = computed(() => activeRegisterMapping.value?.register_template.factor || 1);
  const defaultOffset = computed(() => activeRegisterMapping.value?.register_template.offset || 0);

  const effectiveUnit = computed(() => {
    return formData.measurement_point.unit_override || defaultUnit.value || '';
  });

  const warningLowError = computed(() => {
    const low = formData.measurement_point.warning_low;
    const high = formData.measurement_point.warning_high;
    return low !== null && high !== null && low >= high;
  });

  const warningHighError = computed(() => warningLowError.value);

  const alarmLowError = computed(() => {
    const alarmLow = formData.measurement_point.alarm_low;
    const alarmHigh = formData.measurement_point.alarm_high;
    const warningLow = formData.measurement_point.warning_low;

    if (alarmLow === null)
      return false;

    if (alarmHigh !== null && alarmLow >= alarmHigh)
      return true;

    if (warningLow !== null && alarmLow > warningLow)
      return true;

    return false;
  });

  const alarmLowErrorMessage = computed(() => {
    const alarmLow = formData.measurement_point.alarm_low;
    const alarmHigh = formData.measurement_point.alarm_high;
    const warningLow = formData.measurement_point.warning_low;

    if (alarmHigh !== null && alarmLow !== null && alarmLow >= alarmHigh)
      return 'Alarm low must be less than alarm high';

    if (warningLow !== null && alarmLow !== null && alarmLow > warningLow)
      return 'Alarm low should be less than or equal to warning low';

    return '';
  });

  const alarmHighError = computed(() => {
    const alarmLow = formData.measurement_point.alarm_low;
    const alarmHigh = formData.measurement_point.alarm_high;
    const warningHigh = formData.measurement_point.warning_high;

    if (alarmHigh === null)
      return false;

    if (alarmLow !== null && alarmHigh <= alarmLow)
      return true;

    if (warningHigh !== null && alarmHigh < warningHigh)
      return true;

    return false;
  });

  const alarmHighErrorMessage = computed(() => {
    const alarmLow = formData.measurement_point.alarm_low;
    const alarmHigh = formData.measurement_point.alarm_high;
    const warningHigh = formData.measurement_point.warning_high;

    if (alarmLow !== null && alarmHigh !== null && alarmHigh <= alarmLow)
      return 'Alarm high must be greater than alarm low';

    if (warningHigh !== null && alarmHigh !== null && alarmHigh < warningHigh)
      return 'Alarm high should be greater than or equal to warning high';

    return '';
  });

  const hasUnsavedChanges = computed(() => userEditedFields.value.size > 0);

  const canSubmit = computed(() => {
    return !warningLowError.value &&
          !warningHighError.value &&
          !alarmLowError.value &&
          !alarmHighError.value &&
          configurationErrors.value.length === 0;
  });

  function initFormData(registerMapping: RegisterMapping | null) {
    return {
      measurement_point: {
        id: registerMapping?.measurement_point.id || null,
        name: registerMapping?.measurement_point.name || '',
        description: registerMapping?.measurement_point.description || '',
        unit_override: registerMapping?.measurement_point.unit_override || null,
        chart_type_override: registerMapping?.measurement_point.chart_type_override?.toString() || null,
        color_override: registerMapping?.measurement_point.color_override || null,
        // data_collection_enabled: true,
        // polling_interval_seconds: 300,
        factor_override: registerMapping?.measurement_point.factor_override || null,
        offset_override: registerMapping?.measurement_point.offset_override || null,
        alarm_low: registerMapping?.measurement_point.alarm_low || null,
        alarm_high: registerMapping?.measurement_point.alarm_high || null,
        warning_low: registerMapping?.measurement_point.warning_low || null,
        warning_high: registerMapping?.measurement_point.warning_high || null,
        active: true,
        measurement_subtype_id: registerMapping?.measurement_point.measurement_subtype_id?.toString() || null,
        segment_id: registerMapping?.measurement_point.segment_id?.toString() || null
      }
    };
  }

  const formData = useForm(initFormData(activeRegisterMapping.value));

  function initConfigValues() {
    configurationRegisterMappings.value.forEach((mapping) => {
      configValues[mapping.measurement_point.id] = mapping.measurement_point.last_value ?? null;
    });
  }

  function markFieldEdited(fieldPath: string) {
    userEditedFields.value.add(fieldPath);
  }

  function resetEditTracking() {
    userEditedFields.value.clear();
  }

  function mergeFormData(registerMapping: RegisterMapping | null) {
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

  function normalizeValue(value: any) {
    if (value === null || value === undefined)
      return '';
    return String(value).trim();
  }

  function isConfigurationVisible(mapping: RegisterMapping) {
    const conditions = mapping.register_template.visibility_conditions;
    if (!conditions || Object.keys(conditions).length === 0)
      return true;

    for (const [controllerRole, expectedValues] of Object.entries(conditions)) {
      const controllerMapping = configurationRegisterMappings.value.find(
        (m) => m.register_template.group_role === controllerRole &&
              m.register_template.group_name === mapping.register_template.group_name
      );

      if (!controllerMapping)
        continue;

      const currentValue = configValues[controllerMapping.measurement_point.id];
      const normalizedValue = normalizeValue(currentValue);
      const expectedArray = Array.isArray(expectedValues) ? expectedValues : [expectedValues];

      if (!expectedArray.some((expected) => normalizeValue(expected) === normalizedValue))
        return false;
    }

    return true;
  }

  function getConfigFieldClass(mapping: RegisterMapping) {
    const wideFormats = ['ascii_string'];
    if (wideFormats.includes(mapping.register_template.value_format))
      return 'col-12';

    return 'col-md-6 col-lg-4';
  }

  function getGroupIcon(groupName: string) {
    const icons: Record<string, string> = {
      'input_type': 'cilSettings',
      'calibration_gain': 'cilBalanceScale',
      'calibration_offset': 'cilPencil',
      'scale': 'cilResize',
      'frequency': 'cilWaveform',
      'general': 'cilCog'
    };
    return icons[groupName] || 'cilCog';
  }

  function formatGroupName(groupName: string) {
    if (groupName === 'general')
      return 'General Settings';

    return groupName
      .split('_')
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  }

  function handleConfigValueChange(measurementPointId: MeasurementPoint['id'], value: any) {
    configValues[measurementPointId] = value;
    userEditedFields.value.add(`config.${measurementPointId}`);
    validateConfiguration();
  }

  function validateConfiguration() {
    const errors: string[] = [];

    configurationGroups.value.forEach((group) => {
      const groupMappings = group.mappings;
      const mappingsByRole: Record<NonNullable<RegisterTemplate['group_role']>, RegisterMapping> = {};

      groupMappings.forEach((mapping) => {
        if (mapping.register_template.group_role)
          mappingsByRole[mapping.register_template.group_role] = mapping;
      });

      groupMappings.forEach((mapping) => {
        if (!isConfigurationVisible(mapping))
          return;

        const rules = mapping.register_template.validation_rules;
        if (!rules)
          return;

        const currentValue = configValues[mapping.measurement_point.id];

        // required_when validation
        if (rules.required_when) {
          const controllerRole = rules.required_when.group_role;
          const expectedValue = rules.required_when.equals;
          const controller = mappingsByRole[controllerRole];

          if (controller) {
            const controllerValue = normalizeValue(configValues[controller.measurement_point.id]);
            if (controllerValue === normalizeValue(expectedValue)) {
              if (currentValue === null || currentValue === '' || currentValue === undefined) {
                errors.push(
                  `${mapping.register_template.label} is required when ${controller.register_template.label} is ${expectedValue}`
                );
              }
            }
          }
        }

        if (rules.less_than) {
          const comparisonRole = rules.less_than.group_role;
          const comparisonMapping = mappingsByRole[comparisonRole];

          if (comparisonMapping) {
            const comparisonValue = parseFloat(String(configValues[comparisonMapping.measurement_point.id]));
            const currentNumeric = parseFloat(String(currentValue));

            if (!isNaN(currentNumeric) && !isNaN(comparisonValue) && currentNumeric >= comparisonValue) {
              errors.push(
                `${mapping.register_template.label} must be less than ${comparisonMapping.register_template.label}`
              );
            }
          }
        }

        if (rules.greater_than) {
          const comparisonRole = rules.greater_than.group_role;
          const comparisonMapping = mappingsByRole[comparisonRole];

          if (comparisonMapping) {
            const comparisonValue = parseFloat(String(configValues[comparisonMapping.measurement_point.id]));
            const currentNumeric = parseFloat(String(currentValue));

            if (!isNaN(currentNumeric) && !isNaN(comparisonValue) && currentNumeric <= comparisonValue) {
              errors.push(
                `${mapping.register_template.label} must be greater than ${comparisonMapping.register_template.label}`
              );
            }
          }
        }
      });
    });

    configurationErrors.value = errors;
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
    if (!isValid || !canSubmit.value) {
      const firstInvalidElement = document.querySelector('.is-invalid');
      firstInvalidElement?.scrollIntoView({
        behavior: 'smooth',
        block: 'center'
      });
      return;
    }

    processing.value = true;

    const configurationUpdates = Object.entries(configValues)
      .filter(([id]) => userEditedFields.value.has(`config.${id}`))
      .map(([id, value]) => ({
        measurement_point_id: parseInt(id),
        value
      }));

    const url = ROUTES.measurement_points_update.path.replace(':id', String(formData.measurement_point.id));
    const { success, data } = await execute<{
      measurement_point: MeasurementPoint;
      sibling_measurement_points: MeasurementPoint[];
    }>(
      () => axios.put(url, {
        ...formData,
        configuration_updates: configurationUpdates
      }),
      {
        showSuccessToast: true,
        successMessage: `Interface ${props.interface.name} updated successfully`,
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

  // Watchers
  watch(
    activeRegisterMapping,
    (newValue, oldValue) => {
      if (newValue && newValue !== oldValue) {
        resetEditTracking();
        Object.assign(formData, initFormData(newValue));
        initConfigValues();
      }
    },
    { immediate: true }
  );

  watch(
    () => formData.measurement_point.measurement_subtype_id,
    (newValue, oldValue) => {
      if (newValue === oldValue) return;

      const newActiveRegisterMapping = props.interface.register_mappings.find(
        (registerMapping) => registerMapping.register_template.category === selectedSubtype.value?.data_category
      );
      if (newActiveRegisterMapping)
        mergeFormData(newActiveRegisterMapping);
    }
  );

  initConfigValues();
</script>

<style scoped>
  .form-control-color {
    width: 50px;
    padding: 0.25rem;
    cursor: pointer;
  }

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
