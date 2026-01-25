<template>
  <div class="measurement-tab py-3">
    <div class="row g-4">
      <div class="col-md-6">
        <div class="mb-3">
          <CFormLabel class="fw-semibold">
            Device Name <span class="text-danger">*</span>
          </CFormLabel>
          <CFormInput
            :model-value="modelValue.name"
            @update:model-value="updateField('name', $event)"
            :invalid="v$.name.$error"
            placeholder="e.g., Main Water Pump, Temperature Sensor 1"
            required />
          <CFormFeedback v-if="v$.name.$error" invalid>
            {{ v$.name.$errors[0].$message }}
          </CFormFeedback>
          <div class="form-text">
            Give this device a descriptive name that identifies its purpose or location.
          </div>
        </div>

        <div class="mb-3">
          <CFormLabel class="fw-semibold">Description</CFormLabel>
          <CFormTextarea
            :model-value="modelValue.description"
            @update:model-value="updateField('description', $event)"
            rows="2"
            placeholder="Optional notes about this device..." />
        </div>

        <div class="mb-3">
          <CFormLabel class="fw-semibold">
            Measurement Type <span class="text-danger">*</span>
          </CFormLabel>
          <CFormSelect
            :model-value="modelValue.measurement_subtype_id?.toString() || ''"
            @update:model-value="updateField('measurement_subtype_id', $event)"
            :invalid="v$.measurement_subtype_id.$error"
            required>
            <option value="">-- Select Type --</option>
            <optgroup
              v-for="typeGroup in groupedSubtypes"
              :key="typeGroup.type"
              :label="typeGroup.type">
              <option
                v-for="measurementSubtype in typeGroup.subtypes"
                :key="measurementSubtype.id"
                :value="measurementSubtype.id">
                {{ measurementSubtype.name }} ({{ measurementSubtype.default_unit }})
              </option>
            </optgroup>
          </CFormSelect>
          <CFormFeedback v-if="v$.measurement_subtype_id.$error" invalid>
            {{ v$.measurement_subtype_id.$errors[0].$message }}
          </CFormFeedback>
          <div class="form-text">
            Select the type of measurement this device provides.
          </div>
        </div>
      </div>

      <div class="col-md-6">
        <div class="mb-3">
          <CFormLabel class="fw-semibold">Segment</CFormLabel>
          <CFormSelect
            :model-value="modelValue.segment_id?.toString() || ''"
            @update:model-value="updateField('segment_id', $event)">
            <option value="">-- No Segment --</option>
            <option v-for="segment in segments" :key="segment.id" :value="segment.id">
              {{ segment.name }}
            </option>
          </CFormSelect>
          <div class="form-text">
            Optionally assign this device to a segment for organization.
          </div>
        </div>

        <div class="mb-3">
          <CFormLabel class="fw-semibold">Factor Override</CFormLabel>
          <CFormInput
            :model-value="modelValue.factor_override"
            @update:model-value="updateField('factor_override', $event ? parseFloat($event) : null)"
            type="number"
            step="any"
            :placeholder="defaultFactor ? `Default: ${defaultFactor}` : 'Enter factor'" />
          <div class="form-text">
            Value transformation: scaled = (raw × factor) + offset
          </div>
        </div>

        <div class="mb-3">
          <CFormLabel class="fw-semibold">Offset Override</CFormLabel>
          <CFormInput
            :model-value="modelValue.offset_override"
            @update:model-value="updateField('offset_override', $event ? parseFloat($event) : null)"
            type="number"
            step="any"
            :placeholder="defaultOffset ? `Default: ${defaultOffset}` : 'Enter offset'" />
          <div class="form-text">
            Value transformation: scaled = (raw × factor) + offset
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import type { NestedValidations } from '@vuelidate/core';
  import type { Segment } from '@/types/location';
  import type { MeasurementSubtype } from '@/types/measurementPoint';
  import type { RegisterTemplate } from '@/types/plc';

  type MeasurementFormData = {
    name: string;
    description: string | null;
    measurement_subtype_id: MeasurementSubtype['id'] | null;
    segment_id: Segment['id'] | null;
    factor_override: number | null;
    offset_override: number | null;
  };

  const {
    modelValue,
    segments,
    measurementSubtypes,
    registerTemplate,
    v$
  } = defineProps<{
    modelValue: MeasurementFormData;
    segments: Segment[];
    measurementSubtypes: MeasurementSubtype[];
    registerTemplate: RegisterTemplate;
    v$: NestedValidations<MeasurementFormData>;
  }>();

  const emit = defineEmits<{
    (eventName: 'update:modelValue', value: MeasurementFormData): void;
    (eventName: 'field-edited', fieldPath: string): void;
  }>();

  const groupedSubtypes = computed(() => {
    const groups = new Map<string, MeasurementSubtype[]>();
    measurementSubtypes.forEach((subtype) => {
      const typeName = subtype.measurement_type.name;
      if (!groups.has(typeName)) {
        groups.set(typeName, []);
      }
      groups.get(typeName)!.push(subtype);
    });

    return Array.from(groups.entries()).map(([type, subtypes]) => ({
      type,
      subtypes: subtypes.sort((a, b) => a.name.localeCompare(b.name))
    }));
  });

  const defaultFactor = computed(() => registerTemplate.factor);
  const defaultOffset = computed(() => registerTemplate.offset);

  function updateField(field: keyof MeasurementFormData, value: unknown) {
    let parsedValue: MeasurementFormData[typeof field] = value as MeasurementFormData[typeof field];

    if (field === 'measurement_subtype_id' || field === 'segment_id') {
      parsedValue = (value === '' || value === null || value === undefined)
        ? null
        : Number(value);
    }

    emit('update:modelValue', { ...modelValue, [field]: parsedValue });
    emit('field-edited', `measurement_point.${field}`);
  }
</script>

<style scoped>
  .measurement-tab {
    min-height: 300px;
  }
</style>
