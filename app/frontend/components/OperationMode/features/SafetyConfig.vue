<template>
  <div>
    <div
      v-for="rm in safetyFieldMappings"
      :key="rm.measurement_point.id"
      class="mb-2">
      <RegisterField
        v-if="isVisible(rm)"
        :model-value="configValues[rm.measurement_point.id]"
        :register-mapping="rm"
        :is-editing="true"
        @update:model-value="$emit('value-change', rm.measurement_point.id, $event)" />
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed, ref as vueRef } from 'vue';
  import RegisterField from '@/components/RegisterField.vue';
  import { useGroupRegisters } from '@/composables/useGroupRegisters';
  import type { ConfigValues } from '@/composables/useConfigurationValues';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { RegisterMapping } from '@/types/plc';
  import { OM_GROUPS, OM_ROLES } from '@/types/operationMode';

  const { mappings, configValues } = defineProps<{
    mappings: RegisterMapping[];
    configValues: ConfigValues;
  }>();

  defineEmits<{
    (e: 'value-change', measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']): void;
    (e: 'write', measurementPointId: MeasurementPoint['id'], value: NonNullable<MeasurementPoint['last_value']>): void;
  }>();

  const mappingsRef = computed(() => mappings);
  const groupName = vueRef(OM_GROUPS.safety);
  const { mappingsExcept, mpForRole } = useGroupRegisters(mappingsRef, groupName);

  // All fields except emergency stop — they render generically
  const safetyFieldMappings = computed(() =>
    mappingsExcept(OM_ROLES.emergencyStop)
  );

  /**
   * Check visibility_conditions against current configValues.
   * Same logic as useRegisterVisibility but inline for simplicity.
   */
  function isVisible(rm: RegisterMapping) {
    const conditions = rm.register_template.visibility_conditions;
    if (!conditions)
      return true;

    // Find the controller register in the same group
    for (const [controllerRole, expectedValues] of Object.entries(conditions)) {
      const controllerMapping = mappings.find(m =>
        m.register_template.group_name === rm.register_template.group_name &&
        m.register_template.group_role === controllerRole
      );

      if (!controllerMapping)
        continue;

      const currentValue = String(configValues[controllerMapping.measurement_point.id] ?? '');
      const allowed = Array.isArray(expectedValues) ? expectedValues : [expectedValues];

      if (!allowed.map(String).includes(currentValue))
        return false;
    }

    return true;
  }
</script>
