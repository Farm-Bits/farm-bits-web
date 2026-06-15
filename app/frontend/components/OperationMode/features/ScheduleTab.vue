<template>
  <div>
    <ScheduleSlot
      v-for="group in activeGroups"
      :key="group"
      :mappings="mappings"
      :config-values="configValues"
      :group-name="group"
      :slot-number="slotNumber(group)"
      :label="labelFor(group)"
      :removable="true"
      @value-change="handleValueChange"
      @write="handleImmediateWrite" />

    <CButton
      color="primary"
      variant="outline"
      class="w-100"
      :disabled="!slotsRemaining"
      @click="handleAdd">
      + Add schedule
    </CButton>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import ScheduleSlot from './ScheduleSlot.vue';
  import { useSlotGroups } from '@/composables/useSlotGroups';
  import type { ConfigValues } from '@/composables/useConfigurationValues';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { RegisterMapping, SourceIoInfo } from '@/types/plc';

  const { mappings, configValues, availableSources, slotGroupNames, labelFor, slotNumber } = defineProps<{
    mappings: RegisterMapping[];
    configValues: ConfigValues;
    availableSources: SourceIoInfo[];
    slotGroupNames: string[];
    labelFor: (groupName: string) => string;
    slotNumber: (groupName: string) => number;
  }>();

  const emit = defineEmits<{
    (e: 'value-change', measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']): void;
    (e: 'write', measurementPointId: MeasurementPoint['id'], value: NonNullable<MeasurementPoint['last_value']>): void;
  }>();

  const mappingsRef = computed(() => mappings);
  const configValuesRef = computed(() => configValues);
  const slotGroupNamesRef = computed(() => slotGroupNames);

  const { activeGroups, slotsRemaining, nextOffGroup, enabledIdFor } =
    useSlotGroups(mappingsRef, configValuesRef, slotGroupNamesRef);

  function handleAdd() {
    const group = nextOffGroup();
    if (!group)
      return;

    const id = enabledIdFor(group);
    if (id !== undefined)
      emit('value-change', id, 1);
  }

  function handleValueChange(measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']) {
    emit('value-change', measurementPointId, value);
  }

  function handleImmediateWrite(measurementPointId: MeasurementPoint['id'], value: NonNullable<MeasurementPoint['last_value']>) {
    emit('write', measurementPointId, value);
  }
</script>
