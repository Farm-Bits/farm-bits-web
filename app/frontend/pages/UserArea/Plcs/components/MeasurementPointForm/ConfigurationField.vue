<template>
  <div class="configuration-field">
    <CFormLabel class="fw-semibold d-flex align-items-center gap-2">
      {{ mapping.register_template.label }}
      <CTooltip v-if="mapping.register_template.description" :content="mapping.register_template.description">
        <template #toggler="{ id, on }">
          <CIcon v-on="on" icon="cilInfo" size="sm" class="text-muted" />
        </template>
      </CTooltip>
    </CFormLabel>

    <!-- Numeric -->
    <template v-if="mapping.register_template.value_format === 'numeric'">
      <div class="input-group">
        <CFormInput
          :model-value="currentValue"
          @update:model-value="handleChange"
          type="number"
          :step="numericStep"
          :min="mapping.register_template.min_value"
          :max="mapping.register_template.max_value"
          :disabled="mapping.register_template.read_only"
          :placeholder="placeholder" />
      </div>
      <div v-if="hasMinMax" class="form-text">
        Range: {{ mapping.register_template.min_value }} - {{ mapping.register_template.max_value }}
      </div>
    </template>

    <!-- Boolean (Switch) -->
    <template v-else-if="mapping.register_template.value_format === 'boolean'">
      <div class="form-check form-switch">
        <input
          type="checkbox"
          class="form-check-input"
          :id="`config-${mapping.register_template.id}`"
          :checked="booleanValue"
          :disabled="mapping.register_template.read_only"
          @change="handleBooleanChange" />
        <label class="form-check-label" :for="`config-${mapping.register_template.id}`">
          {{ booleanValue ? 'Enabled' : 'Disabled' }}
        </label>
      </div>
    </template>

    <!-- Enum (Select) -->
    <template v-else-if="mapping.register_template.value_format === 'enum'">
      <CFormSelect
        :model-value="currentValue"
        @update:model-value="handleChange"
        :disabled="mapping.register_template.read_only">
        <option value="">-- Select --</option>
        <option
          v-for="(label, value) in enumOptions"
          :key="value"
          :value="value">
          {{ label }}
        </option>
      </CFormSelect>
    </template>

    <!-- ASCII String -->
    <template v-else-if="mapping.register_template.value_format === 'ascii_string'">
      <CFormInput
        :model-value="currentValue"
        @update:model-value="handleChange"
        type="text"
        :maxlength="maxStringLength"
        :disabled="mapping.register_template.read_only"
        :placeholder="placeholder" />
      <div v-if="maxStringLength" class="form-text">
        Max length: {{ maxStringLength }} characters
      </div>
    </template>

    <!-- Time (HH:MM) -->
    <template v-else-if="mapping.register_template.value_format === 'time_of_day'">
      <CFormInput
        :model-value="currentValue"
        @update:model-value="handleChange"
        type="time"
        :disabled="mapping.register_template.read_only"
        step="60" />
      <div class="form-text">Time of day (HH:MM)</div>
    </template>

    <!-- Duration -->
    <template v-else-if="mapping.register_template.value_format === 'duration_seconds'">
      <div class="input-group">
        <CFormInput
          :model-value="durationHours"
          @update:model-value="handleDurationSecondsChange('hours', $event)"
          type="number"
          min="0"
          max="99"
          :disabled="mapping.register_template.read_only"
          placeholder="HH"
          style="max-width: 80px" />
        <span class="input-group-text">h</span>
        <CFormInput
          :model-value="durationMinutes"
          @update:model-value="handleDurationSecondsChange('minutes', $event)"
          type="number"
          min="0"
          max="59"
          :disabled="mapping.register_template.read_only"
          placeholder="MM"
          style="max-width: 80px" />
        <span class="input-group-text">m</span>
        <CFormInput
          :model-value="durationSeconds"
          @update:model-value="handleDurationSecondsChange('seconds', $event)"
          type="number"
          min="0"
          max="59"
          :disabled="mapping.register_template.read_only"
          placeholder="SS"
          style="max-width: 80px" />
        <span class="input-group-text">s</span>
      </div>
      <div class="form-text">Duration (hours, minutes, seconds)</div>
    </template>

    <!-- Default (text input) -->
    <template v-else>
      <CFormInput
        :model-value="currentValue"
        @update:model-value="handleChange"
        :disabled="mapping.register_template.read_only"
        :placeholder="placeholder" />
    </template>

    <!-- Read-only indicator -->
    <div v-if="mapping.register_template.read_only" class="form-text text-warning">
      <CIcon icon="cilLockLocked" size="sm" class="me-1" />
      Read-only (cannot be modified)
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { RegisterMapping } from '@/types/plc';

  export type ConfigValues = Record<MeasurementPoint['id'], MeasurementPoint['last_value']>;

  const props = defineProps<{
    mapping: RegisterMapping;
    configValues: ConfigValues;
    allMappings: RegisterMapping[];
  }>();

  const emit = defineEmits<{
    (e: 'update', measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']): void;
  }>();

  const currentValue = computed(() => {
    return props.configValues[props.mapping.measurement_point.id] ?? '';
  });

  const booleanValue = computed(() => {
    const val = currentValue.value;

    if (typeof val === 'boolean')
      return val;

    if (val === 'true' || val === '1' || val === 1)
      return true;

    return false;
  });

  const enumOptions = computed<Record<string, string>>(() => {
    return props.mapping.register_template.enum_values || {};
  });

  const numericStep = computed(() => {
    const dataType = props.mapping.register_template.data_type;
    if (dataType.includes('float') || dataType.includes('double'))
      return 'any';

    return '1';
  });

  function parseDurationSeconds(value: string | number | null) {
    if (value === null || value === undefined || value === '')
      return { hours: 0, minutes: 0, seconds: 0 };

    // If it's a string like "HH:MM:SS" or "MM:SS"
    if (typeof value === 'string' && value.includes(':')) {
      const parts = value.split(':').map(Number);
      if (parts.length === 3)
        return { hours: parts[0], minutes: parts[1], seconds: parts[2] };
      else if (parts.length === 2)
        return { hours: 0, minutes: parts[0], seconds: parts[1] };
    }

    // If it's total seconds
    const totalSeconds = typeof value === 'number' ? value : parseInt(value, 10) || 0;
    return {
      hours: Math.floor(totalSeconds / 3600),
      minutes: Math.floor((totalSeconds % 3600) / 60),
      seconds: totalSeconds % 60
    };
  }

  const durationParts = computed(() => parseDurationSeconds(currentValue.value));
  const durationHours = computed(() => durationParts.value.hours);
  const durationMinutes = computed(() => durationParts.value.minutes);
  const durationSeconds = computed(() => durationParts.value.seconds);

  const hasMinMax = computed(() => {
    return props.mapping.register_template.min_value !== null &&
          props.mapping.register_template.max_value !== null;
  });

  const maxStringLength = computed(() => {
    if (props.mapping.register_template.value_format === 'ascii_string')
      return props.mapping.register_template.address_count * 2;

    return null;
  });

  const placeholder = computed(() => {
    if (props.mapping.register_template.default_value !== null)
      return `Default: ${props.mapping.register_template.default_value}`;

    return 'Enter value';
  });

  function handleChange(value: any) {
    let processedValue = value;

    if (props.mapping.register_template.value_format === 'numeric')
      processedValue = value === '' ? null : parseFloat(value);

    emit('update', props.mapping.measurement_point.id, processedValue);
  }

  function handleBooleanChange(event: Event) {
    const checked = (event.target as HTMLInputElement).checked;
    emit('update', props.mapping.measurement_point.id, Number(checked));
  }

  function handleDurationSecondsChange(part: 'hours' | 'minutes' | 'seconds', value: string) {
    const current = durationParts.value;
    const newValue = parseInt(value, 10) || 0;

    const updated = { ...current, [part]: newValue };

    const formatted = [
      updated.hours.toString().padStart(2, '0'),
      updated.minutes.toString().padStart(2, '0'),
      updated.seconds.toString().padStart(2, '0')
    ].join(':');

    emit('update', props.mapping.measurement_point.id, formatted);
  }
</script>

<style scoped>
  .configuration-field {
    margin-bottom: 0;
  }

  .form-check-input:checked {
    background-color: var(--cui-success);
    border-color: var(--cui-success);
  }
</style>
