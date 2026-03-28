<template>
  <div>
    <!-- Command buttons from enum_values — no filtering, register template
         is the source of truth for which commands are user-actionable -->
    <div
      v-if="commandOptions.length > 0"
      class="d-flex gap-2 flex-wrap mb-3">
      <CButton
        v-for="opt in commandOptions"
        :key="opt.value"
        :color="opt.color"
        :variant="opt.variant"
        size="sm"
        :disabled="isWriting"
        @click="handleCommand(opt.value)">
        {{ opt.label }}
      </CButton>
    </div>

    <!-- Duration input (shown when command requires it, via visibility_conditions) -->
    <div
      v-for="rm in visibleParameterMappings"
      :key="rm.measurement_point.id"
      class="mb-2">
      <RegisterField
        :model-value="paramValues[rm.measurement_point.id]"
        :register-mapping="rm"
        :is-editing="true"
        @update:model-value="handleParamChange(rm.measurement_point.id, $event)" />
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed, reactive, ref } from 'vue';
  import RegisterField from '@/components/RegisterField.vue';
  import { useGroupRegisters } from '@/composables/useGroupRegisters';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { RegisterMapping } from '@/types/plc';
  import { OM_GROUPS, OM_ROLES } from '@/types/operationMode';

  const { mappings } = defineProps<{
    mappings: RegisterMapping[];
  }>();

  const emit = defineEmits<{
    (e: 'write', measurementPointId: MeasurementPoint['id'], value: NonNullable<MeasurementPoint['last_value']>): void;
  }>();

  const mappingsRef = computed(() => mappings);
  const groupName = ref(OM_GROUPS.manual);
  const { getValue, mpForRole, templateForRole, mappingsExcept } = useGroupRegisters(mappingsRef, groupName);

  const isWriting = ref(false);

  // ── Command buttons ──────────────────────────────

  /**
   * All enum values from the command register become buttons.
   * The register template's enum_values IS the contract for user-actionable
   * commands. If a value shouldn't be a button, remove it from enum_values
   * in the seed data — the frontend renders everything the backend provides.
   *
   * Button color is derived from position: first = success (primary action),
   * last = danger (stop/off action), middle = info. This is a reasonable
   * default because enum_values are ordered by key, and PLC conventions
   * typically put "on" commands first and "off" last.
   */
  const commandOptions = computed(() => {
    const rt = templateForRole(OM_ROLES.command);
    if (!rt?.enum_values)
      return [];

    const entries = Object.entries(rt.enum_values);
    const lastIndex = entries.length - 1;

    return entries.map(([value, label], index) => ({
      value,
      label,
      color: index === 0 ? 'success' : index === lastIndex ? 'danger' : 'info',
      variant: 'outline' as const,
    }));
  });

  // ── Parameter fields (duration, etc.) ────────────

  const parameterMappings = computed(() => mappingsExcept(OM_ROLES.command));

  const paramValues = reactive<Record<number, MeasurementPoint['last_value']>>({});

  // Initialize param values from current measurement point values
  for (const rm of parameterMappings.value) {
    paramValues[rm.measurement_point.id] = rm.measurement_point.last_value;
  }

  // Visibility: respect visibility_conditions on parameter registers
  const visibleParameterMappings = computed(() => {
    const commandValue = getValue(OM_ROLES.command);

    return parameterMappings.value.filter(rm => {
      const conditions = rm.register_template.visibility_conditions;
      if (!conditions)
        return true;

      for (const [controllerRole, expectedValues] of Object.entries(conditions)) {
        const controllerValue = getValue(controllerRole);
        const allowed = Array.isArray(expectedValues) ? expectedValues : [expectedValues];
        if (!allowed.includes(String(controllerValue)))
          return false;
      }

      return true;
    });
  });

  function handleParamChange(measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']) {
    paramValues[measurementPointId] = value;
  }

  // ── Write handling ───────────────────────────────

  async function handleCommand(commandValue: string) {
    const commandMp = mpForRole(OM_ROLES.command);
    if (!commandMp)
      return;

    isWriting.value = true;

    try {
      // Write parameter values first (e.g., duration), then command
      for (const rm of visibleParameterMappings.value) {
        const val = paramValues[rm.measurement_point.id];
        if (val !== null && val !== undefined)
          emit('write', rm.measurement_point.id, val);
      }

      // Write the command last — PLC reads parameters before executing
      emit('write', commandMp.id, commandValue);
    } finally {
      isWriting.value = false;
    }
  }
</script>
