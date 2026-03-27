<template>
  <div class="d-flex align-items-center gap-2 flex-wrap">
    <!-- All status registers rendered generically -->
    <template
      v-for="rm in visibleMappings"
      :key="rm.measurement_point.id">
      <!-- Countdown timer: special rendering for duration_seconds with live tick -->
      <div
        v-if="isCountdownRole(rm) && countdownSeconds > 0"
        class="d-flex align-items-center gap-1">
        <small class="text-body-secondary">
          {{ rm.register_template.name }}:
        </small>
        <CBadge
          color="info"
          shape="rounded-pill">
          {{ formatCountdown(countdownSeconds) }}
        </CBadge>
      </div>

      <!-- All other roles: RegisterField in read-only mode handles
           enum → badge, bitmask → badge list, boolean → badge, etc. -->
      <div
        v-else-if="rm.measurement_point.last_value !== null"
        class="d-flex align-items-center gap-1">
        <small class="text-body-secondary">
          {{ rm.register_template.name }}:
        </small>
        <RegisterField
          :register-mapping="rm"
          :model-value="rm.measurement_point.last_value"
          :is-editing="false" />
      </div>
    </template>
  </div>
</template>

<script lang="ts" setup>
  import { computed, ref, onMounted, onUnmounted } from 'vue';
  import RegisterField from '@/components/RegisterField.vue';
  import { useGroupRegisters } from '@/composables/useGroupRegisters';
  import type { RegisterMapping } from '@/types/plc';
  import { OM_GROUPS, OM_ROLES } from '@/types/operationMode';

  const { mappings } = defineProps<{
    mappings: RegisterMapping[];
  }>();

  const mappingsRef = computed(() => mappings);
  const groupName = ref(OM_GROUPS.status);
  const { getNumericValue, mpForRole, mappingForRole } = useGroupRegisters(mappingsRef, groupName);

  // ── Visibility filtering ────────────────────────

  const statusMappings = computed(() =>
    mappings
      .filter(rm =>
        rm.register_template.group_name === OM_GROUPS.status &&
        rm.register_template.group_role !== null
      )
      .sort((a, b) => a.position - b.position)
  );

  /**
   * Filter by visibility_conditions.
   * Each status register can declare conditions (e.g., next_change_time
   * is only visible when active_source is a timed source).
   */
  const visibleMappings = computed(() =>
    statusMappings.value.filter(rm => {
      const conditions = rm.register_template.visibility_conditions;
      if (!conditions)
        return true;

      for (const [controllerRole, expectedValues] of Object.entries(conditions)) {
        const controllerMp = mappings.find((m) =>
          m.register_template.group_name === OM_GROUPS.status &&
          m.register_template.group_role === controllerRole
        );

        if (!controllerMp)
          continue;

        const currentValue = String(controllerMp.measurement_point.last_value ?? '');
        const allowed = Array.isArray(expectedValues) ? expectedValues : [expectedValues];

        if (!allowed.map(String).includes(currentValue))
          return false;
      }

      return true;
    })
  );

  // ── Countdown timer (the only truly custom piece) ──

  function isCountdownRole(rm: RegisterMapping): boolean {
    return rm.register_template.group_role === OM_ROLES.nextChangeTime &&
      rm.register_template.value_format === 'duration_seconds';
  }

  /**
   * Live countdown: reads the PLC value and ticks down locally
   * between poll refreshes. Resets when the PLC value changes.
   */
  const countdownSeconds = ref(0);
  let countdownInterval: ReturnType<typeof setInterval> | null = null;
  let lastPlcValue: number | null = null;

  function syncCountdown() {
    const plcValue = getNumericValue(OM_ROLES.nextChangeTime);

    if (plcValue !== lastPlcValue) {
      // PLC value changed (new poll data arrived) — reset local counter
      lastPlcValue = plcValue;
      countdownSeconds.value = plcValue > 0 ? plcValue : 0;
    }
  }

  function tickCountdown() {
    // Sync with PLC value first (handles poll refreshes)
    syncCountdown();

    // Then tick down locally
    if (countdownSeconds.value > 0)
      countdownSeconds.value = countdownSeconds.value - 1;
  }

  onMounted(() => {
    syncCountdown();
    countdownInterval = setInterval(tickCountdown, 1000);
  });

  onUnmounted(() => {
    if (countdownInterval)
      clearInterval(countdownInterval);
  });

  function formatCountdown(totalSeconds: number): string {
    const h = Math.floor(totalSeconds / 3600);
    const m = Math.floor((totalSeconds % 3600) / 60);
    const s = totalSeconds % 60;

    if (h > 0)
      return `${h}h ${m}m`;

    if (m > 0)
      return `${m}m ${s}s`;

    return `${s}s`;
  }
</script>
