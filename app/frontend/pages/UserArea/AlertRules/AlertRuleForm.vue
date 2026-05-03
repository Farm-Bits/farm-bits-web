<!-- app/javascript/Pages/AlertRules/AlertRuleForm.vue -->
<template>
  <form @submit.prevent="onSubmit">
    <div class="row g-3">
      <!-- ── Basic info ─────────────────────────────── -->
      <div class="col-12">
        <CFormLabel for="name">Rule Name *</CFormLabel>
        <CFormInput
          id="name"
          v-model="form.name"
          placeholder="e.g. High Tank Temperature"
          :invalid="!!fieldError('name')"
          required />
        <CFormFeedback v-if="fieldError('name')" invalid>{{ fieldError('name') }}</CFormFeedback>
      </div>

      <div class="col-md-6">
        <CFormLabel for="measurement_point_id">Measurement Point *</CFormLabel>
        <CFormSelect
          id="measurement_point_id"
          v-model.number="form.measurement_point_id"
          :disabled="isEditing"
          :invalid="!!fieldError('measurement_point_id')"
          required>
          <option :value="null">Select a measurement point...</option>
          <option
            v-for="mp in measurementPoints"
            :key="mp.id"
            :value="mp.id">
            {{ mp.name }} ({{ mp.segment_name }}) — {{ mp.value_format }}
          </option>
        </CFormSelect>
        <CFormText v-if="isEditing">
          The measurement point cannot be changed after creation.
        </CFormText>
        <CFormFeedback v-if="fieldError('measurement_point_id')" invalid>
          {{ fieldError('measurement_point_id') }}
        </CFormFeedback>
      </div>

      <div class="col-md-6">
        <CFormLabel for="severity">Severity *</CFormLabel>
        <CFormSelect id="severity" v-model="form.severity" required>
          <option value="info">Info</option>
          <option value="warning">Warning</option>
          <option value="critical">Critical</option>
        </CFormSelect>
      </div>

      <!-- ── Condition type ─────────────────────────── -->
      <div class="col-12">
        <hr class="my-2" />
        <h5 class="mb-3">Condition</h5>
      </div>

      <div class="col-md-6">
        <CFormLabel for="condition_type">Condition Type *</CFormLabel>
        <CFormSelect
          id="condition_type"
          v-model="form.condition_type"
          @change="onConditionTypeChange"
          :disabled="!selectedMeasurementPoint"
          required>
          <option
            v-for="option in availableConditionTypes"
            :key="option.value"
            :value="option.value">
            {{ option.label }}
          </option>
        </CFormSelect>
        <CFormText v-if="!selectedMeasurementPoint">
          Select a measurement point first.
        </CFormText>
      </div>

      <!-- ── Direction (status_change | threshold) ──── -->
      <div v-if="form.condition_type === 'status_change'" class="col-md-6">
        <CFormLabel for="direction">Trigger When *</CFormLabel>
        <CFormSelect id="direction" v-model="form.direction" required>
          <option value="to_on">Status changes to ON</option>
          <option value="to_off">Status changes to OFF</option>
          <option value="both">Status changes either way</option>
        </CFormSelect>
      </div>

      <div v-if="form.condition_type === 'threshold'" class="col-md-3">
        <CFormLabel for="direction">Direction *</CFormLabel>
        <CFormSelect id="direction" v-model="form.direction" required>
          <option value="above">Above</option>
          <option value="below">Below</option>
        </CFormSelect>
      </div>

      <div v-if="form.condition_type === 'threshold'" class="col-md-3">
        <CFormLabel for="threshold_value">Threshold *</CFormLabel>
        <div class="input-group">
          <CFormInput
            id="threshold_value"
            type="number"
            step="any"
            v-model.number="form.threshold_value"
            :invalid="!!fieldError('threshold_value')"
            required />
          <span v-if="thresholdUnit" class="input-group-text">{{ thresholdUnit }}</span>
        </div>
        <CFormFeedback v-if="fieldError('threshold_value')" invalid>
          {{ fieldError('threshold_value') }}
        </CFormFeedback>
      </div>

      <!-- ── Inactivity ─────────────────────────────── -->
      <div v-if="form.condition_type === 'inactivity'" class="col-md-6">
        <CFormLabel for="inactivity_seconds">No data for at least *</CFormLabel>
        <div class="input-group">
          <CFormInput
            id="inactivity_seconds"
            type="number"
            min="1"
            step="1"
            v-model.number="form.inactivity_seconds"
            :invalid="!!fieldError('inactivity_seconds')"
            required />
          <span class="input-group-text">seconds</span>
        </div>
        <CFormText v-if="form.inactivity_seconds && form.inactivity_seconds > 0">
          ≈ {{ formatDuration(form.inactivity_seconds) }}
        </CFormText>
      </div>

      <!-- ── Dwell ──────────────────────────────────── -->
      <div v-if="dwellApplicable" class="col-md-6">
        <CFormLabel for="min_duration_seconds">Minimum Duration</CFormLabel>
        <div class="input-group">
          <CFormInput
            id="min_duration_seconds"
            type="number"
            min="0"
            step="1"
            v-model.number="form.min_duration_seconds" />
          <span class="input-group-text">seconds</span>
        </div>
        <CFormText>
          Condition must hold for this long before the alert opens.
          Leave empty or 0 to fire on the first reading.
          <span v-if="form.min_duration_seconds && form.min_duration_seconds > 0">
            (≈ {{ formatDuration(form.min_duration_seconds) }})
          </span>
        </CFormText>
      </div>

      <!-- ── Active ─────────────────────────────────── -->
      <div class="col-12">
        <hr class="my-2" />
        <CFormSwitch
          id="active"
          label="Rule is active"
          v-model="form.active" />
        <CFormText>Inactive rules do not evaluate or fire alerts.</CFormText>
      </div>

      <!-- ── Submit ─────────────────────────────────── -->
      <div class="col-12 d-flex justify-content-end gap-2 mt-3">
        <CButton color="secondary" variant="outline" type="button" @click="$emit('cancel')">
          Cancel
        </CButton>
        <CButton color="primary" type="submit" :disabled="!isValid">
          {{ submitLabel }}
        </CButton>
      </div>
    </div>
  </form>
</template>

<script lang="ts" setup>
  import { reactive, computed, ref, watch } from 'vue';
  import { formatDuration } from '@/utils/alertFormatters';
  import type {
    AlertRule,
    AlertSeverity,
    AlertConditionType,
    AlertDirection,
    MeasurementPointOption
  } from '@/types/alerts';

  const props = defineProps<{
    initialRule: AlertRule | null;
    measurementPoints: MeasurementPointOption[];
    submitLabel: string;
  }>();

  const emit = defineEmits<{
    submit: [payload: Record<string, any>];
    cancel: [];
  }>();

  interface FormState {
    name: string;
    severity: AlertSeverity;
    condition_type: AlertConditionType;
    direction: AlertDirection;
    threshold_value: number | null;
    inactivity_seconds: number | null;
    min_duration_seconds: number | null;
    active: boolean;
    measurement_point_id: number | null;
  }

  const form = reactive<FormState>({
    name: props.initialRule?.name ?? '',
    severity: props.initialRule?.severity ?? 'warning',
    condition_type: props.initialRule?.condition_type ?? 'threshold',
    direction: props.initialRule?.direction ?? 'above',
    threshold_value: props.initialRule?.threshold_value ?? null,
    inactivity_seconds: props.initialRule?.inactivity_seconds ?? null,
    min_duration_seconds: props.initialRule?.min_duration_seconds ?? null,
    active: props.initialRule?.active ?? true,
    measurement_point_id: props.initialRule?.measurement_point_id ?? null
  });

  const fieldErrors = ref<Record<string, string>>({});

  const isEditing = computed<boolean>(() => props.initialRule !== null);

  const selectedMeasurementPoint = computed<MeasurementPointOption | null>(() => {
    if (!form.measurement_point_id) {
      return null;
    }
    return props.measurementPoints.find(mp => mp.id === form.measurement_point_id) ?? null;
  });

  // Available condition types depend on the MP's value_format.
  // status_change requires boolean; threshold requires numeric.
  // inactivity is universal.
  const availableConditionTypes = computed<{ value: AlertConditionType; label: string }[]>(() => {
    const mp = selectedMeasurementPoint.value;
    if (!mp) {
      return [];
    }

    const options: { value: AlertConditionType; label: string }[] = [];

    if (mp.value_format === 'boolean') {
      options.push({ value: 'status_change', label: 'Status change' });
    }

    if (mp.value_format === 'numeric') {
      options.push({ value: 'threshold', label: 'Threshold crossing' });
    }

    options.push({ value: 'inactivity', label: 'Inactivity (no data received)' });

    return options;
  });

  // Status change with dwell is rejected by the AlertRule model:
  // status_change is an edge predicate, dwell is meaningless on it.
  const dwellApplicable = computed<boolean>(() => {
    return form.condition_type === 'threshold' || form.condition_type === 'inactivity';
  });

  const thresholdUnit = computed<string>(() => {
    return selectedMeasurementPoint.value?.unit ?? '';
  });

  const isValid = computed<boolean>(() => {
    if (!form.name.trim() || !form.measurement_point_id) {
      return false;
    }

    if (form.condition_type === 'threshold') {
      if (form.threshold_value === null || form.threshold_value === undefined) {
        return false;
      }
      if (!form.direction) {
        return false;
      }
    }

    if (form.condition_type === 'status_change' && !form.direction) {
      return false;
    }

    if (form.condition_type === 'inactivity') {
      if (!form.inactivity_seconds || form.inactivity_seconds < 1) {
        return false;
      }
    }

    return true;
  });

  // When MP or condition type changes, fix up direction and clear
  // fields that are no longer relevant. Keeps the payload tidy and
  // matches the model's "absence" validations.
  watch(() => form.condition_type, (newType) => {
    if (newType === 'status_change') {
      form.direction = form.direction === 'to_on' || form.direction === 'to_off' || form.direction === 'both'
        ? form.direction
        : 'to_on';
      form.threshold_value = null;
      form.inactivity_seconds = null;
      form.min_duration_seconds = null;
    } else if (newType === 'threshold') {
      form.direction = form.direction === 'above' || form.direction === 'below'
        ? form.direction
        : 'above';
      form.inactivity_seconds = null;
    } else if (newType === 'inactivity') {
      form.direction = null;
      form.threshold_value = null;
    }
  });

  // When the MP changes, snap condition_type to the first compatible
  // option if the current one is no longer valid.
  watch(() => form.measurement_point_id, () => {
    const valid = availableConditionTypes.value.map(o => o.value);
    if (valid.length === 0) {
      return;
    }

    if (!valid.includes(form.condition_type)) {
      form.condition_type = valid[0];
    }
  });

  function fieldError(field: string): string | null {
    return fieldErrors.value[field] ?? null;
  }

  function onConditionTypeChange(): void {
    fieldErrors.value = {};
  }

  function onSubmit(): void {
    if (!isValid.value) {
      return;
    }

    // Strip nulls for fields that should be absent for the chosen
    // condition type — matches the model's "absence" validations.
    const payload: Record<string, any> = {
      name: form.name.trim(),
      severity: form.severity,
      condition_type: form.condition_type,
      active: form.active,
      measurement_point_id: form.measurement_point_id,
      min_duration_seconds: form.min_duration_seconds || 0
    };

    if (form.condition_type === 'status_change' || form.condition_type === 'threshold') {
      payload.direction = form.direction;
    }

    if (form.condition_type === 'threshold') {
      payload.threshold_value = form.threshold_value;
    }

    if (form.condition_type === 'inactivity') {
      payload.inactivity_seconds = form.inactivity_seconds;
    }

    emit('submit', payload);
  }
</script>
