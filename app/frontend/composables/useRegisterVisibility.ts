import { computed, type Ref } from 'vue';
import type { RegisterMapping } from '@/types/plc';
import { normalizeValue } from '@/utils/registerUtils';
import type { ConfigValues } from './useConfigurationValues';

export function useRegisterVisibility(
  allRegisterMappings: Ref<RegisterMapping[]>,
  configValues: Ref<ConfigValues>
) {
  function isVisible(registerMapping: RegisterMapping) {
    const { register_template } = registerMapping;
    const conditions = register_template.visibility_conditions;

    if (!conditions || Object.keys(conditions).length === 0)
      return true;

    return Object.entries(conditions).every(([controllerRole, expectedValues]) => {
      const controllerMapping = allRegisterMappings.value.find(
        (currentMapping) =>
          currentMapping.register_template.group_name === register_template.group_name &&
          currentMapping.register_template.group_role === controllerRole
      );

      if (!controllerMapping)
        return false;

      const currentValue = configValues.value[controllerMapping.measurement_point.id];
      const normalizedValue = normalizeValue(currentValue);
      const expected = Array.isArray(expectedValues) ? expectedValues : [expectedValues];

      return expected.includes(normalizedValue);
    });
  }

  const visibleMappings = computed(() => {
    return allRegisterMappings.value.filter(isVisible);
  });

  const visibleCount = computed(() => visibleMappings.value.length);

  return {
    isVisible,
    visibleMappings,
    visibleCount
  };
}
