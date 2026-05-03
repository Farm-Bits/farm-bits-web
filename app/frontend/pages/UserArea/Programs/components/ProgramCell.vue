<template>
  <div class="program-cell" :class="{ 'program-cell--pending': hasPendingChange }">
    <RegisterField
      :register-mapping="mapping"
      :model-value="currentValue"
      :is-editing="!isReadOnly"
      size="compact"
      @update:model-value="emit('update:value', $event)" />
  </div>
</template>

<script setup lang="ts">
  import { computed } from 'vue';
  import RegisterField from '@/components/RegisterField.vue';
  import type { RegisterMapping } from '@/types/plc';
  import type { MeasurementPoint } from '@/types/measurementPoint';

  type CellValue = MeasurementPoint['last_value'];

  const props = defineProps<{
    mapping: RegisterMapping;
    pendingValue: CellValue | undefined;
    hasPendingChange: boolean;
  }>();

  const emit = defineEmits<{
    (e: 'update:value', value: CellValue): void;
  }>();

  // Show pending value if user has edited; otherwise server's last known value.
  const currentValue = computed<CellValue>(() => {
    if (props.hasPendingChange)
      return props.pendingValue ?? null;

    return props.mapping.measurement_point.last_value;
  });

  // Read-only registers (e.g. program_status loaded_mark) render as
  // ValueDisplay; writable ones render as ValueEdit. RegisterField switches
  // on `is-editing`.
  const isReadOnly = computed(() => props.mapping.register_template.read_only);
</script>

<style scoped>
  .program-cell {
    position: relative;
    padding: 0.125rem;
    border-radius: 4px;
    transition: background-color 0.15s ease;
  }

  .program-cell--pending {
    background-color: var(--cui-warning-bg-subtle, #fff3cd);
    box-shadow: inset 0 0 0 1px var(--cui-warning-border-subtle, #ffe69c);
  }
</style>
