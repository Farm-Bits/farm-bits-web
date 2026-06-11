<template>
  <div class="value-edit" :class="rootClasses">
    <!-- Numeric -->
    <div v-if="valueFormat === 'numeric'" class="input-group">
      <CFormInput
        :model-value="editValue"
        @update:model-value="handleNumericChange"
        type="number"
        :step="numericStep"
        :min="minValue ?? undefined"
        :max="maxValue ?? undefined"
        :disabled="disabled"
        :invalid="invalid"
        :placeholder="placeholder" />
      <span v-if="unit" class="input-group-text">{{ unit }}</span>
    </div>

    <!-- Boolean (Switch) -->
    <div v-else-if="valueFormat === 'boolean'" class="form-check form-switch">
      <input
        type="checkbox"
        class="form-check-input"
        :id="fieldId"
        :checked="booleanEditValue"
        :disabled="disabled"
        @change="handleBooleanChange" />
      <label class="form-check-label" :for="fieldId">
        {{ booleanLabel }}
      </label>
    </div>

    <!-- Enum (Select) -->
    <CFormSelect
      v-else-if="valueFormat === 'enum'"
      :model-value="editValue"
      @update:model-value="handleEnumChange"
      :disabled="disabled"
      :invalid="invalid">
      <option value="">-- Select --</option>
      <option v-for="(label, value) in enumValues" :key="value" :value="value">
        {{ label }}
      </option>
    </CFormSelect>

    <!-- ASCII String -->
    <CFormInput
      v-else-if="valueFormat === 'ascii_string'"
      :model-value="editValue"
      @update:model-value="handleStringChange"
      type="text"
      :maxlength="maxStringLength ?? undefined"
      :disabled="disabled"
      :invalid="invalid"
      :placeholder="placeholder" />

    <!-- Time of Day (HH:MM) -->
    <CFormInput
      v-else-if="valueFormat === 'time_of_day'"
      :model-value="timeEditValue"
      @update:model-value="handleTimeChange"
      type="time"
      :disabled="disabled"
      :invalid="invalid"
      step="60" />

    <!-- Duration Seconds (HH:MM:SS) -->
    <div v-else-if="valueFormat === 'duration_seconds'" class="input-group">
      <CFormInput
        :model-value="durationParts.hours"
        @update:model-value="handleDurationChange('hours', $event)"
        type="number"
        min="0"
        max="99"
        :disabled="disabled"
        placeholder="HH"
        style="max-width: 80px" />
      <span class="input-group-text">h</span>
      <CFormInput
        :model-value="durationParts.minutes"
        @update:model-value="handleDurationChange('minutes', $event)"
        type="number"
        min="0"
        max="59"
        :disabled="disabled"
        placeholder="MM"
        style="max-width: 80px" />
      <span class="input-group-text">m</span>
      <CFormInput
        :model-value="durationParts.seconds"
        @update:model-value="handleDurationChange('seconds', $event)"
        type="number"
        min="0"
        max="59"
        :disabled="disabled"
        placeholder="SS"
        style="max-width: 80px" />
      <span class="input-group-text">s</span>
    </div>

    <!-- Bitmask (Checkboxes per bit) -->
    <div v-else-if="valueFormat === 'bitmask' && enumValues" class="bitmask-edit">
      <CFormCheck
        v-for="(label, bitStr) in enumValues"
        :key="bitStr"
        :id="`${fieldId}-bit-${bitStr}`"
        :label="label"
        :checked="isBitSet(Number(bitStr))"
        :disabled="disabled"
        inline
        @change="handleBitmaskToggle(Number(bitStr), $event)" />
    </div>

    <!-- Bitmask without enum_values (raw numeric input) -->
    <div v-else-if="valueFormat === 'bitmask'" class="input-group">
      <CFormInput
        :model-value="editValue"
        @update:model-value="handleNumericChange"
        type="number"
        :min="minValue ?? 0"
        :max="maxValue ?? undefined"
        step="1"
        :disabled="disabled"
        :invalid="invalid"
        :placeholder="placeholder" />
    </div>

    <!-- Default (text input) -->
    <CFormInput
      v-else
      :model-value="editValue"
      @update:model-value="handleStringChange"
      :disabled="disabled"
      :invalid="invalid"
      :placeholder="placeholder" />
  </div>
</template>

<script lang="ts" setup>
  import { computed, ref, watch } from 'vue';
  import { valueConverters } from '@/utils/valueConverters';
  import type { ValueFormat } from '@/types/plc';

  const props = withDefaults(defineProps<{
    modelValue: string | number | null;
    valueFormat: ValueFormat;
    dataType?: string;
    unit?: string | null;
    enumValues?: Record<string, string> | null;
    minValue?: number | null;
    maxValue?: number | null;
    defaultValue?: string | number | null;
    addressCount?: number;
    disabled?: boolean;
    invalid?: boolean;
    size?: 'compact' | 'default' | 'large';
  }>(), {
    size: 'default'
  });

  const rootClasses = computed(() => [`value-edit--${props.size}`]);

  const emit = defineEmits<{
    (eventName: 'update:modelValue', value: string | number | null): void;
  }>();

  const fieldId = `field-${Math.random().toString(36).substring(7)}`;

  const editValue = ref(props.modelValue);

  const numericStep = computed(() => {
    const dataTypeTmp = props.dataType ?? '';
    if (dataTypeTmp.includes('float') || dataTypeTmp.includes('double'))
      return 'any';

    return '1';
  });

  const maxStringLength = computed(() => {
    if (props.valueFormat === 'ascii_string' && props.addressCount)
      return props.addressCount * 2;

    return null;
  });

  const placeholder = computed(() => {
    if (props.defaultValue)
      return `Default: ${props.defaultValue}`;

    return 'Enter value';
  });

  const booleanEditValue = computed(() => {
    return valueConverters.boolean.toEdit(editValue.value);
  });

  const booleanLabel = computed(() => {
    if (!props.unit)
      return booleanEditValue.value ? 'Enabled' : 'Disabled';

    const options = props.unit.split('/');
    const index = booleanEditValue.value ? 1 : 0;
    return options[index] ?? (booleanEditValue.value ? 'Enabled' : 'Disabled');
  });

  const timeEditValue = computed(() => {
    return valueConverters.timeOfDay.toEdit(editValue.value);
  });

  const durationParts = computed(() => {
    return valueConverters.durationSeconds.toEdit(editValue.value);
  });

  function isBitSet(bit: number) {
    return valueConverters.bitmask.isBitSet(editValue.value, bit);
  }

  function handleBitmaskToggle(bit: number, event: Event) {
    const checked = (event.target as HTMLInputElement).checked;
    const toggled = valueConverters.bitmask.toggleBit(editValue.value, bit, checked);
    const sanitized = valueConverters.bitmask.sanitize(toggled, props.enumValues ?? null);
    emit('update:modelValue', sanitized);
  }

  function handleNumericChange(value: string) {
    const converted = valueConverters.numeric.fromEdit(value);
    emit('update:modelValue', converted);
  }

  function handleBooleanChange(event: Event) {
    const checked = (event.target as HTMLInputElement).checked;
    const converted = valueConverters.boolean.fromEdit(checked);
    emit('update:modelValue', converted);
  }

  function handleEnumChange(value: string) {
    const converted = valueConverters.enum.fromEdit(value);
    emit('update:modelValue', converted);
  }

  function handleStringChange(value: string) {
    const converted = valueConverters.asciiString.fromEdit(value);
    emit('update:modelValue', converted);
  }

  function handleTimeChange(value: string) {
    const converted = valueConverters.timeOfDay.fromEdit(value);
    emit('update:modelValue', converted);
  }

  function handleDurationChange(part: 'hours' | 'minutes' | 'seconds', value: string) {
    const currentParts = durationParts.value;
    const newPartValue = parseInt(value, 10) || 0;
    const updated = { ...currentParts, [part]: newPartValue };
    const converted = valueConverters.durationSeconds.fromEdit(updated);
    // ✅ Update local ref immediately so durationParts recomputes before the
    //    parent round-trip — prevents sibling inputs resetting mid-edit
    editValue.value = converted;
    emit('update:modelValue', converted);
  }

  watch(() => props.modelValue, (newValue) => {
    if (props.valueFormat === 'bitmask' && props.enumValues) {
      editValue.value = valueConverters.bitmask.sanitize(newValue, props.enumValues);
      return;
    }

    editValue.value = newValue;
  }, { immediate: true });
</script>

<style scoped>
  .value-edit {
    margin-bottom: 0;
  }

  .form-check-input:checked {
    background-color: var(--cui-success);
    border-color: var(--cui-success);
  }

  .bitmask-edit {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    padding: 0.375rem 0;
  }

  .value-edit--compact :deep(.form-control),
  .value-edit--compact :deep(.form-select) {
    font-size: 0.85rem;
    padding: 0.25rem 0.5rem;
    min-height: auto;
  }

  .value-edit--compact :deep(.input-group-text) {
    font-size: 0.75rem;
    padding: 0.25rem 0.5rem;
  }

  .value-edit--compact :deep(.form-check-label) {
    font-size: 0.85rem;
  }
</style>
