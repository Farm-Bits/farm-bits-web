<template>
  <div class="register-field">
    <ValueDisplay
      v-if="!isEditing"
      :value="registerMapping.measurement_point.last_value"
      :valueFormat="registerMapping.register_template.value_format"
      :enumValues="registerMapping.register_template.enum_values"
      :alarmLow="registerMapping.measurement_point.alarm_low"
      :alarmHigh="registerMapping.measurement_point.alarm_high"
      :warningLow="registerMapping.measurement_point.warning_low"
      :warningHigh="registerMapping.measurement_point.warning_high"
      :alarmState="registerMapping.measurement_point.alarm_state" />

    <ValueEdit
      v-else
      :model-value="modelValue"
      :valueFormat="registerMapping.register_template.value_format"
      :dataType="registerMapping.register_template.data_type"
      :unit="registerMapping.measurement_point.effective_unit"
      :enumValues="registerMapping.register_template.enum_values"
      :minValue="registerMapping.register_template.min_value"
      :maxValue="registerMapping.register_template.max_value"
      :defaultValue="registerMapping.register_template.default_value"
      :addressCount="registerMapping.register_template.address_count"
      :disabled="disabled"
      :invalid="invalid"
      @update:model-value="$emit('update:modelValue', $event)" />

    <div v-if="invalid && validationError" class="invalid-feedback d-block">
      {{ validationError }}
    </div>

    <div
      v-if="isEditing && hasMinMax"
      class="form-text">
      Range: {{ registerMapping.register_template.min_value }} - {{ registerMapping.register_template.max_value }}
    </div>

    <div
      v-if="isEditing && maxStringLength"
      class="form-text">
      Max length: {{ maxStringLength }} characters
    </div>

    <div
      v-if="isEditing && registerMapping.register_template.value_format === 'time_of_day'"
      class="form-text">
      Time of day (HH:MM)
    </div>

    <div
      v-if="isEditing && registerMapping.register_template.value_format === 'duration_seconds'"
      class="form-text">
      Duration (hours, minutes, seconds)
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import ValueDisplay from '@/components/ValueDisplay.vue';
  import ValueEdit from '@/components/ValueEdit.vue';
  import type { RegisterMapping } from '@/types/plc';
  import type { MeasurementPoint } from '@/types/measurementPoint';

  const {
    modelValue,
    registerMapping,
    isEditing,
    disabled,
    invalid,
    validationError
  } = defineProps<{
    registerMapping: RegisterMapping;
    modelValue: MeasurementPoint['last_value'];
    isEditing: boolean;
    disabled?: boolean;
    invalid?: boolean;
    validationError?: string | null;
  }>();

  defineEmits<{
    (eventName: 'update:modelValue', value: MeasurementPoint['last_value']): void;
  }>();

  const hasMinMax = computed(() => {
    return registerMapping.register_template.min_value !== null &&
          registerMapping.register_template.max_value !== null;
  });

  const maxStringLength = computed(() => {
    if (registerMapping.register_template.value_format === 'ascii_string')
      return registerMapping.register_template.address_count * 2;

    return null;
  });
</script>

<style scoped>
  .register-field {
    margin-bottom: 0;
  }
</style>
