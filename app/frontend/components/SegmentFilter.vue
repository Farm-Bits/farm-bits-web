<template>
  <div class="segment-filter">
    <CFormLabel class="mb-1 small text-body-secondary">Segment</CFormLabel>
    <CFormSelect
      :model-value="modelValue != null ? String(modelValue) : ''"
      size="sm"
      @update:model-value="emit('update:modelValue', $event === '' ? null : Number($event))">
      <option value="">All Segments</option>
      <option
        v-for="segment in segments"
        :key="segment.id"
        :value="segment.id">
        {{ segment.name }}
      </option>
    </CFormSelect>
  </div>
</template>

<script lang="ts" setup>
  import type { Segment } from '@/types/location';

  const { segments, modelValue } = defineProps<{
    segments: Segment[];
    modelValue: Segment['id'] | null;
  }>();

  const emit = defineEmits<{
    (e: 'update:modelValue', value: Segment['id'] | null): void;
  }>();
</script>
