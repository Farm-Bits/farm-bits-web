import { computed, type Ref } from 'vue';
import type { RegisterMapping } from '@/types/plc';
import { OM_GROUPS, type OmGroupNameOrSlot } from '@/types/operationMode';

export type OperationModeTab = {
  id: string;
  label: string;
};

export function useOperationMode(
  mappings: Ref<RegisterMapping[]>,
  groupLabels: Ref<Record<OmGroupNameOrSlot | string, string>>
) {
  /**
   * All group names present in the mappings, with their register mappings.
   */
  const groups = computed(() => {
    const map = new Map<OmGroupNameOrSlot | string, RegisterMapping[]>();

    for (const rm of mappings.value) {
      const gn = rm.register_template.group_name;
      if (!gn)
        continue;

      if (!map.has(gn))
        map.set(gn, []);

      map.get(gn)!.push(rm);
    }

    return map;
  });

  // ── Feature detection ──────────────────────────────

  const hasStatus = computed(() => groups.value.has(OM_GROUPS.status));
  const hasManual = computed(() => groups.value.has(OM_GROUPS.manual));
  const hasDutyCycle = computed(() => groups.value.has(OM_GROUPS.dutyCycle));
  const hasSensor = computed(() => groups.value.has(OM_GROUPS.sensor));
  const hasWindow = computed(() => groups.value.has(OM_GROUPS.window));
  const hasSafety = computed(() => groups.value.has(OM_GROUPS.safety));

  /**
   * Numbered schedule slot groups, sorted naturally.
   */
  const scheduleGroups = computed(() =>
    sortedNumberedGroups(OM_GROUPS.schedule)
  );

  /**
   * Numbered sensor condition groups, sorted naturally.
   */
  const sensorConditionGroups = computed(() =>
    sortedNumberedGroups(OM_GROUPS.sensorCondition)
  );

  const hasSchedules = computed(() => scheduleGroups.value.length > 0);
  const hasSensorConditions = computed(() => sensorConditionGroups.value.length > 0);

  /**
   * Whether this interface has any Operation Mode registers at all.
   */
  const hasOperationMode = computed(() =>
    hasStatus.value || hasManual.value || hasDutyCycle.value ||
    hasSensor.value || hasSchedules.value || hasSafety.value || hasWindow.value
  );

  // ── Label resolution ───────────────────────────────

  /**
   * Get the user-facing label for a group name.
   * Uses the pre-resolved group_labels from the backend.
   * Falls back to a cleaned-up version of the group name.
   */
  function labelFor(groupName: OmGroupNameOrSlot | string) {
    const labels = groupLabels.value;
    if (labels[groupName])
      return labels[groupName];

    // Fallback: om_duty_cycle → Duty Cycle
    return groupName
      .replace(/^om_/, '')
      .replace(/_\d+$/, '')
      .replace(/_/g, ' ')
      .replace(/\b\w/g, c => c.toUpperCase());
  }

  /**
   * Get slot number from a numbered group name.
   * 'om_schedule_3' → 3, 'om_sensor_cond_11' → 11
   */
  function slotNumber(groupName: OmGroupNameOrSlot | string) {
    const match = groupName.match(/_(\d+)$/);
    return match ? parseInt(match[1], 10) : 0;
  }

  /**
   * Get mappings for a specific group.
   */
  function mappingsFor(groupName: OmGroupNameOrSlot | string) {
    return groups.value.get(groupName) || [];
  }

  // ── Tab generation ─────────────────────────────────

  const tabs = computed<OperationModeTab[]>(() => {
    const t: OperationModeTab[] = [];

    // if (hasStatus.value || hasManual.value) {
    //   t.push({
    //     id: 'control',
    //     label: tabLabel([OM_GROUPS.status, OM_GROUPS.manual], 'Control'),
    //   });
    // }
    if (hasDutyCycle.value) {
      t.push({
        id: 'dutycycle',
        label: labelFor(OM_GROUPS.dutyCycle),
      });
    }
    if (hasSensor.value || hasSensorConditions.value) {
      t.push({
        id: 'sensors',
        label: tabLabel([OM_GROUPS.sensor], 'Sensors'),
      });
    }
    if (hasSchedules.value) {
      t.push({
        id: 'schedules',
        label: tabLabel([scheduleGroups.value[0]], 'Schedules'),
      });
    }
    if (hasSafety.value || hasWindow.value) {
      t.push({
        id: 'settings',
        label: tabLabel([OM_GROUPS.safety, OM_GROUPS.window], 'Settings'),
      });
    }

    return t;
  });

  // ── Private helpers ────────────────────────────────

  function sortedNumberedGroups(prefix: OmGroupNameOrSlot | string) {
    const pattern = new RegExp(`^${prefix}_\\d+$`);
    return [...groups.value.keys()]
      .filter((name) => pattern.test(name))
      .sort((a, b) => {
        const numA = parseInt(a.split('_').pop()!, 10);
        const numB = parseInt(b.split('_').pop()!, 10);
        return numA - numB;
      });
  }

  function tabLabel(groupNames: (OmGroupNameOrSlot | string)[], fallback: string) {
    if (groupNames.length === 1 && groupNames[0])
      return labelFor(groupNames[0]);

    return fallback;
  }

  return {
    groups,
    hasStatus,
    hasManual,
    hasDutyCycle,
    hasSensor,
    hasWindow,
    hasSafety,
    hasSchedules,
    hasSensorConditions,
    hasOperationMode,
    scheduleGroups,
    sensorConditionGroups,
    tabs,
    labelFor,
    slotNumber,
    mappingsFor,
  };
}
