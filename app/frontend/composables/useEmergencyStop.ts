import { computed, type ComputedRef, type Ref } from 'vue';
import type { RegisterMapping } from '@/types/plc';

// ── Exported types ───────────────────────────────────────

/**
 * A writable register that acts as an emergency stop for an output.
 *
 * Discovered structurally — never by a firmware-specific value — so the
 * same component works across firmwares. `mapping` is the write target;
 * `isActive` is that register's current state.
 */
export type EmergencyStopInfo = {
  mapping: RegisterMapping;
  isActive: boolean;
};

// ── Helpers ──────────────────────────────────────────────

/**
 * Detect an emergency stop register by its structural contract:
 * a writable boolean carrying group_role 'emergency_stop'.
 *
 * The contract is the group_role marker — not any value, address, or enum
 * slot. A firmware that models e-stop differently (e.g. an enum) would be
 * matched by the same marker; only the isActive interpretation below would
 * gain a branch.
 */
function isEmergencyStop(rm: RegisterMapping): boolean {
  const rt = rm.register_template;
  return rt.value_format === 'boolean' &&
    !rt.read_only &&
    rt.group_role === 'emergency_stop';
}

// ── Composable ───────────────────────────────────────────

/**
 * Locates the emergency stop register among a set of register mappings and
 * reports whether it is currently active. Returns null when no e-stop
 * register is present, so callers fail safe (no e-stop UI is shown).
 */
export function useEmergencyStop(
  mappings: Ref<RegisterMapping[]>
): { emergencyStop: ComputedRef<EmergencyStopInfo | null> } {
  const emergencyStop = computed<EmergencyStopInfo | null>(() => {
    const mapping = mappings.value.find(isEmergencyStop);
    if (!mapping)
      return null;

    // Boolean e-stop: active when the register's own value is true.
    // Reads the register's value, not a firmware-specific constant.
    return {
      mapping,
      isActive: String(mapping.measurement_point.last_value) === '1',
    };
  });

  return { emergencyStop };
}
