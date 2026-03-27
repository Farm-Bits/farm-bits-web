<template>
  <div>
    <!-- Master enable -->
    <div class="d-flex align-items-center gap-2 p-3 rounded border mb-3"
      :class="isEnabled ? 'border-success-subtle bg-success-subtle' : ''">
      <CFormSwitch
        :model-value="isEnabled"
        @update:model-value="handleMasterToggle" />
      <span :class="isEnabled ? 'fw-semibold' : 'text-body-secondary'">
        Sensor Trigger
      </span>
    </div>

    <p class="text-body-secondary small mb-3">
      Output ON when <strong class="text-body">any</strong> enabled condition is met (OR logic).
    </p>

    <!-- Condition slots -->
    <SensorCondition
      v-for="condGroupName in conditionGroupNames"
      :key="condGroupName"
      :mappings="mappings"
      :group-name="condGroupName"
      :condition-number="slotNumber(condGroupName)"
      :label="labelFor(condGroupName)"
      :config-values="configValues"
      :available-sources="availableSources"
      @value-change="(mpId, val) => $emit('value-change', mpId, val)" />

    <p
      v-if="conditionGroupNames.length === 0"
      class="text-body-secondary text-center p-3 border rounded">
      No sensor condition slots available.
    </p>
  </div>
</template>

<script lang="ts" setup>
  import { computed, ref as vueRef } from 'vue';
  import SensorCondition from './SensorCondition.vue';
  import { useGroupRegisters } from '@/composables/useGroupRegisters';
  import type { ConfigValues } from '@/composables/useConfigurationValues';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { RegisterMapping, SourceIoInfo } from '@/types/plc';
  import { OM_GROUPS, OM_ROLES, type OmGroupNameOrSlot } from '@/types/operationMode';

  const { mappings, conditionGroupNames, configValues, availableSources, labelFor, slotNumber } = defineProps<{
    mappings: RegisterMapping[];
    conditionGroupNames: string[];
    configValues: ConfigValues;
    availableSources: SourceIoInfo[];
    labelFor: (groupName: OmGroupNameOrSlot | string) => string;
    slotNumber: (groupName: OmGroupNameOrSlot | string) => number;
  }>();

  const emit = defineEmits<{
    (e: 'value-change', measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']): void;
  }>();

  const mappingsRef = computed(() => mappings);
  const groupName = vueRef(OM_GROUPS.sensor);
  const { mpForRole } = useGroupRegisters(mappingsRef, groupName);

  const isEnabled = computed(() => {
    const mpId = mpForRole(OM_ROLES.enabled)?.id;
    if (!mpId)
      return false;

    return String(configValues[mpId]) === '1';
  });

  function handleMasterToggle(value: boolean) {
    const mp = mpForRole(OM_ROLES.enabled);
    if (mp)
      emit('value-change', mp.id, value ? 1 : 0);
  }
</script>
