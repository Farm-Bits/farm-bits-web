import { computed, type Ref } from 'vue';
import type { RegisterMapping } from '@/types/plc';
import type { OmGroupNameOrSlot, OmRole } from '@/types/operationMode';

export function useGroupRegisters(
  mappings: Ref<RegisterMapping[]>,
  groupName: Ref<OmGroupNameOrSlot | string>
) {
  /**
   * All registers in this group, indexed by group_role.
   */
  const byRole = computed(() => {
    const map = new Map<OmRole | string, RegisterMapping>();

    for (const rm of mappings.value) {
      const rt = rm.register_template;
      if (rt.group_name !== groupName.value || !rt.group_role)
        continue;

      map.set(rt.group_role, rm);
    }

    return map;
  });

  /**
   * Get the full RegisterMapping for a role.
   */
  function getByRole(role: OmRole | string) {
    return byRole.value.get(role);
  }

  /**
   * Get the current last_value for a role (string from measurement point).
   */
  function getValue(role: OmRole | string) {
    const val = getByRole(role)?.measurement_point.last_value;
    if (val === null || val === undefined)
      return null;

    return String(val);
  }

  /**
   * Get the numeric value for a role (parsed from string).
   */
  function getNumericValue(role: OmRole | string) {
    const val = getValue(role);
    if (val === null)
      return 0;

    return Number(val) || 0;
  }

  /**
   * Get the measurement point for a role (for building write payloads).
   */
  function mpForRole(role: OmRole | string) {
    return getByRole(role)?.measurement_point;
  }

  /**
   * Get the register template for a role (for metadata: enum_values, min/max, etc.)
   */
  function templateForRole(role: OmRole | string) {
    return getByRole(role)?.register_template;
  }

  /**
   * Get the RegisterMapping for a role (for passing to RegisterField).
   */
  function mappingForRole(role: OmRole | string) {
    return getByRole(role);
  }

  /**
   * All roles that exist in this group.
   */
  const roles = computed(() => [...byRole.value.keys()]);

  /**
   * All mappings in this group except the specified roles, sorted by position.
   * Used to render "everything else" generically via RegisterField.
   */
  function mappingsExcept(...excludedRoles: (OmRole | string)[]) {
    const excluded = new Set<string>(excludedRoles);

    return mappings.value
      .filter((rm) => {
        const rt = rm.register_template;
        return rt.group_name === groupName.value &&
          rt.group_role !== null &&
          !excluded.has(rt.group_role);
      })
      .sort((a, b) => a.position - b.position);
  }

  return {
    byRole,
    roles,
    getByRole,
    getValue,
    getNumericValue,
    mpForRole,
    templateForRole,
    mappingForRole,
    mappingsExcept,
  };
}
