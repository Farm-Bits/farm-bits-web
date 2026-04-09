import { computed, type Ref } from 'vue';
import type { RegisterMapping } from '@/types/plc';
import { isOmCommandGroup, type OmGroupNameOrSlot } from '@/types/operationMode';

// ── Exported types ───────────────────────────────────────

/**
 * A single action derived from a command register's enum_values.
 */
export type CommandAction = {
  enumKey: string;
  label: string;
  /** Sibling registers whose visibility_conditions match this command value */
  paramMappings: RegisterMapping[];
};

/**
 * A group that has a writable enum register (the "command").
 */
export type CommandGroup = {
  groupName: string;
  groupLabel: string;
  commandMapping: RegisterMapping;
  actions: CommandAction[];
};

/**
 * A group that has a writable boolean 'enabled' register.
 * Discovered by: value_format === 'boolean' && !read_only && group_role === 'enabled'
 * (group_role 'enabled' is the convention — but the discovery is structural,
 * not by testing against the OM_ROLES constant in the Live components).
 */
export type FeatureToggle = {
  groupName: string;
  groupLabel: string;
  enabledMapping: RegisterMapping;
  isEnabled: boolean;
  /**
   * Sibling registers that have validation_rules.required_when referencing
   * the enabled register's role with equals '1'.
   * If non-empty, enabling requires a params modal.
   */
  paramMappings: RegisterMapping[];
};

/**
 * A register that acts as an emergency stop toggle.
 * Discovered by: the register template's name or label contains 'emergency'
 * AND value_format === 'boolean' AND !read_only.
 * This is intentionally defensive — if the convention changes, the card
 * simply won't show an e-stop section (fails safe).
 */
export type EmergencyStopInfo = {
  mapping: RegisterMapping;
  isActive: boolean;
};

// ── Helpers ──────────────────────────────────────────────

/**
 * Detect if a register acts as a "command" — a writable enum register.
 * This is the structural signature of command registers in OM groups.
 */
function isCommandRegister(rm: RegisterMapping) {
  const rt = rm.register_template;
  return isOmCommandGroup(rt.group_name as string) &&
    rt.value_format === 'enum' &&
    !rt.read_only &&
    rt.enum_values !== null &&
    Object.keys(rt.enum_values).length > 0;
}

/**
 * Detect if a register acts as a feature "enabled" toggle —
 * a writable boolean register with group_role 'enabled'.
 */
function isEnabledToggle(rm: RegisterMapping) {
  const rt = rm.register_template;
  return rt.value_format === 'boolean' &&
    !rt.read_only &&
    rt.group_role === 'enabled';
}

/**
 * Detect emergency stop: writable boolean whose group_role is 'emergency_stop'.
 */
function isEmergencyStop(rm: RegisterMapping) {
  const rt = rm.register_template;
  return rt.value_format === 'boolean' &&
    !rt.read_only &&
    rt.group_role === 'emergency_stop';
}

// ── Main composable ──────────────────────────────────────

export function useQuickActions(
  mappings: Ref<RegisterMapping[]>,
  groupLabels: Ref<Record<OmGroupNameOrSlot | string, string>>,
  configValues: Record<number, string | number | null>
) {
  // ── Group mappings by group_name ──

  const groupedMappings = computed(() => {
    const map = new Map<string, RegisterMapping[]>();
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

  // ── Resolve a group label from the backend-provided group_labels ──

  function resolveLabel(groupName: string) {
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

  // ── Command groups ──
  //
  // A command group has a writable enum register. Each enum entry
  // becomes a button. Siblings whose visibility_conditions reference
  // the command register's group_role with a specific enum key are
  // params for that command.

  const commandGroups = computed<CommandGroup[]>(() => {
    const groups: CommandGroup[] = [];

    for (const [groupName, groupMappings] of groupedMappings.value) {
      const cmdMapping = groupMappings.find(isCommandRegister);
      if (!cmdMapping)
        continue;

      const enumValues = cmdMapping.register_template.enum_values!;
      const cmdRole = cmdMapping.register_template.group_role;
      if (!cmdRole)
        continue;

      const readOnlyKeys = new Set(cmdMapping.register_template.read_only_enum_keys ?? []);
      const actions: CommandAction[] = Object.entries(enumValues)
        .filter(([enumKey]) => !readOnlyKeys.has(enumKey))
        .map(([enumKey, label]) => {
        // Find siblings visible only when command === enumKey
        const paramMappings = groupMappings.filter(rm => {
          if (rm.register_template.id === cmdMapping.register_template.id)
            return false;

          if (rm.register_template.read_only)
            return false;

          const vc = rm.register_template.visibility_conditions;
          if (!vc || !vc[cmdRole])
            return false;

          const expected = Array.isArray(vc[cmdRole]) ? vc[cmdRole] : [vc[cmdRole]];
          return expected.includes(enumKey);
        });

        return { enumKey, label, paramMappings };
      });

      groups.push({
        groupName,
        groupLabel: resolveLabel(groupName),
        commandMapping: cmdMapping,
        actions,
      });
    }

    return groups;
  });

  // ── Feature toggles ──
  //
  // Any group with a writable boolean 'enabled' register.
  // Command groups are excluded (they already appear as command buttons).

  const commandGroupNames = computed(() =>
    new Set(commandGroups.value.map(cg => cg.groupName))
  );

  const featureToggles = computed<FeatureToggle[]>(() => {
    const toggles: FeatureToggle[] = [];

    for (const [groupName, groupMappings] of groupedMappings.value) {
      // Skip groups that already have a command (rendered as buttons)
      if (commandGroupNames.value.has(groupName))
        continue;

      const enabledMapping = groupMappings.find(isEnabledToggle);
      if (!enabledMapping)
        continue;

      const enabledRole = enabledMapping.register_template.group_role;
      if (!enabledRole)
        continue;

      const currentValue = configValues[enabledMapping.measurement_point.id]
        ?? enabledMapping.measurement_point.last_value;
      const isEnabled = String(currentValue) === '1';

      // Find params needed when enabling: siblings with
      // validation_rules.required_when referencing the enabled role with equals '1'
      const paramMappings = groupMappings.filter(rm => {
        if (rm.register_template.id === enabledMapping.register_template.id)
          return false;

        if (rm.register_template.read_only)
          return false;

        const vr = rm.register_template.validation_rules;
        if (!vr)
          return false;

        if (vr.required_when) {
          if (vr.required_when.group_role === enabledRole &&
            String(vr.required_when.equals) === '1')
            return true;
        }

        if (vr.required_when_any) {
          return vr.required_when_any.some(cond =>
            cond.group_role === enabledRole &&
            String(cond.equals) === '1'
          );
        }

        return false;
      });

      toggles.push({
        groupName,
        groupLabel: resolveLabel(groupName),
        enabledMapping,
        isEnabled,
        paramMappings,
      });
    }

    return toggles;
  });

  // ── Emergency stop ──
  //
  // Any writable boolean register with group_role 'emergency_stop'.

  const emergencyStop = computed<EmergencyStopInfo | null>(() => {
    for (const [, groupMappings] of groupedMappings.value) {
      const estopMapping = groupMappings.find(isEmergencyStop);
      if (estopMapping) {
        const currentValue = configValues[estopMapping.measurement_point.id]
          ?? estopMapping.measurement_point.last_value;
        return {
          mapping: estopMapping,
          isActive: String(currentValue) === '1',
        };
      }
    }
    return null;
  });

  // ── Status display ──
  //
  // Read-only registers — the card shows these for context.
  // Discovered structurally: read_only registers with enum or numeric value_format.

  const statusMappings = computed<RegisterMapping[]>(() => {
    const result: RegisterMapping[] = [];
    for (const [, groupMappings] of groupedMappings.value) {
      for (const rm of groupMappings) {
        if (rm.register_template.read_only &&
          rm.register_template.category === 'operation_mode_status')
          result.push(rm);
      }
    }
    return result.sort((a, b) => a.position - b.position);
  });

  return {
    commandGroups,
    featureToggles,
    emergencyStop,
    statusMappings,
    groupedMappings,
    resolveLabel,
  };
}
