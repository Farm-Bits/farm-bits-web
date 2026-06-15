import { computed, type Ref } from 'vue';
import type { RegisterMapping } from '@/types/plc';
import type { ConfigValues } from './useConfigurationValues';
import { OM_ROLES } from '@/types/operationMode';

// Slot lifecycle for numbered groups (schedules, sensor conditions). A slot is
// "on" when its enabled register is 1. Add turns on the first off slot in order;
// Remove turns one off. Mirrors the mobile screen's addSlot/removeSlot rules.
export function useSlotGroups(
  mappings: Ref<RegisterMapping[]>,
  configValues: Ref<ConfigValues>,
  slotGroupNames: Ref<string[]>
) {
  function enabledMappingFor(group: string) {
    return mappings.value.find(rm =>
      rm.register_template.group_name === group &&
      rm.register_template.group_role === OM_ROLES.enabled
    );
  }

  function isGroupOn(group: string) {
    const enabled = enabledMappingFor(group);
    if (!enabled)
      return true;

    return String(configValues.value[enabled.measurement_point.id]) === '1';
  }

  function enabledIdFor(group: string) {
    return enabledMappingFor(group)?.measurement_point.id;
  }

  function nextOffGroup() {
    return slotGroupNames.value.find(group => !isGroupOn(group));
  }

  const activeGroups = computed(() =>
    slotGroupNames.value.filter(group => isGroupOn(group))
  );

  const slotsRemaining = computed(() =>
    slotGroupNames.value.some(group => !isGroupOn(group))
  );

  return {
    isGroupOn,
    enabledIdFor,
    nextOffGroup,
    activeGroups,
    slotsRemaining
  };
}
