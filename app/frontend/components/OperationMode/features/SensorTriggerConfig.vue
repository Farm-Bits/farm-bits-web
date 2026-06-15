<template>
  <div>
    <!-- Master enable -->
    <div
      v-if="enabledMapping"
      class="d-flex align-items-center gap-2 p-3 rounded border mb-3"
      :class="isEnabled ? 'border-success-subtle bg-success-subtle' : ''">
      <CFormLabel class="fw-semibold d-flex align-items-center gap-2">
        {{ enabledMapping.register_template.name }}
        <CTooltip
          v-if="enabledMapping.register_template.description"
          :content="enabledMapping.register_template.description">
          <template #toggler="{ on }">
            <CIcon v-on="on" icon="cilInfo" size="sm" class="text-muted" />
          </template>
        </CTooltip>
      </CFormLabel>
      <CFormSwitch
        :model-value="isEnabled"
        @update:model-value="handleMasterToggle" />
      <span :class="isEnabled ? 'fw-semibold' : 'text-body-secondary'">
        Sensor Trigger
      </span>
    </div>

    <!-- Conditions only appear while the master trigger is on -->
    <template v-if="isEnabled">
      <p class="text-body-secondary small mb-3">
        Output ON when <strong class="text-body">any</strong> enabled condition is met (OR logic).
      </p>

      <SensorCondition
        v-for="condGroupName in activeGroups"
        :key="condGroupName"
        :mappings="mappings"
        :group-name="condGroupName"
        :condition-number="slotNumber(condGroupName)"
        :label="labelFor(condGroupName)"
        :config-values="configValues"
        :available-sources="availableSources"
        :removable="true"
        @value-change="handleValueChange" />

      <p
        v-if="conditionGroupNames.length === 0"
        class="text-body-secondary text-center p-3 border rounded">
        No sensor condition slots available.
      </p>
      <CButton
        v-else
        color="primary"
        variant="outline"
        class="w-100"
        :disabled="!slotsRemaining"
        @click="handleAddCondition">
        + Add condition
      </CButton>
    </template>
  </div>
</template>

<script lang="ts" setup>
  import { computed, ref as vueRef } from 'vue';
  import SensorCondition from './SensorCondition.vue';
  import { useGroupRegisters } from '@/composables/useGroupRegisters';
  import { useSlotGroups } from '@/composables/useSlotGroups';
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
  const configValuesRef = computed(() => configValues);
  const conditionGroupNamesRef = computed(() => conditionGroupNames);
  const groupName = vueRef(OM_GROUPS.sensor);

  const { mpForRole, mappingForRole } = useGroupRegisters(mappingsRef, groupName);
  const { activeGroups, slotsRemaining, nextOffGroup, enabledIdFor } =
    useSlotGroups(mappingsRef, configValuesRef, conditionGroupNamesRef);

  const isEnabled = computed(() => {
    const mpId = mpForRole(OM_ROLES.enabled)?.id;
    if (!mpId)
      return false;

    return String(configValues[mpId]) === '1';
  });

  const enabledMapping = computed(() => mappingForRole(OM_ROLES.enabled));

  function handleMasterToggle(value: boolean) {
    const mp = mpForRole(OM_ROLES.enabled);
    if (mp)
      emit('value-change', mp.id, value ? 1 : 0);
  }

  function handleAddCondition() {
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
</script>
