<template>
  <div class="group-by-toggle">
    <CFormLabel class="mb-1 small text-body-secondary">Group by</CFormLabel>
    <div class="btn-group btn-group-sm d-flex">
      <button
        type="button"
        class="btn"
        :class="modelValue === 'measurement_subtype' ? 'btn-primary' : 'btn-outline-secondary'"
        @click="emit('update:modelValue', 'measurement_subtype')">
        Measurement Type
      </button>
      <button
        type="button"
        class="btn"
        :class="modelValue === 'segment' ? 'btn-primary' : 'btn-outline-secondary'"
        @click="emit('update:modelValue', 'segment')">
        Segment
      </button>
    </div>
  </div>
</template>

<script lang="ts" setup>
  export type GroupBy = 'measurement_subtype' | 'segment';

  const { modelValue } = defineProps<{
    modelValue: GroupBy;
  }>();

  const emit = defineEmits<{
    (e: 'update:modelValue', value: GroupBy): void;
  }>();
</script>

<style scoped>
  .btn-group .btn {
    font-size: 0.8125rem;
  }
</style>
