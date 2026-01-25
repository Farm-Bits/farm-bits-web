import { computed, ref, watch, type Ref } from 'vue';
import type { RegisterMapping } from '@/types/plc';
import type { MeasurementPoint } from '@/types/measurementPoint';
import { normalizeValue, buildRoleMapping, groupMappingsByName } from '@/utils/registerUtils';

export type ConfigValues = Record<MeasurementPoint['id'], MeasurementPoint['last_value']>;

export function useRegisterValidation(
  allRegisterMappings: Ref<RegisterMapping[]>,
  configValues: Ref<ConfigValues>,
  isVisible: (registerMapping: RegisterMapping) => boolean
) {
  const errors = ref<string[]>([]);

  function validateField(
    registerMapping: RegisterMapping,
    mappingsByRole: Map<string, RegisterMapping>
  ): string[] {
    const fieldErrors: string[] = [];
    const rules = registerMapping.register_template.validation_rules;

    if (!rules)
      return fieldErrors;

    const currentValue = configValues.value[registerMapping.measurement_point.id];

    if (rules.required_when) {
      const controllerRole = rules.required_when.group_role;
      const expectedValue = rules.required_when.equals;
      const controller = mappingsByRole.get(controllerRole);

      if (controller) {
        const controllerValue = normalizeValue(
          configValues.value[controller.measurement_point.id]
        );

        if (controllerValue === normalizeValue(expectedValue)) {
          if (currentValue === null || currentValue === '' || currentValue === undefined) {
            fieldErrors.push(
              rules.message ||
              `${registerMapping.register_template.label} is required when ${controller.register_template.label} is ${expectedValue}`
            );
          }
        }
      }
    }

    if (rules.less_than) {
      const comparisonRole = rules.less_than.group_role;
      const comparisonMapping = mappingsByRole.get(comparisonRole);

      if (comparisonMapping) {
        const comparisonValue = parseFloat(
          String(configValues.value[comparisonMapping.measurement_point.id])
        );
        const currentNumeric = parseFloat(String(currentValue));

        if (!isNaN(currentNumeric) && !isNaN(comparisonValue) && currentNumeric >= comparisonValue) {
          fieldErrors.push(
            rules.message ||
            `${registerMapping.register_template.label} must be less than ${comparisonMapping.register_template.label}`
          );
        }
      }
    }

    if (rules.greater_than) {
      const comparisonRole = rules.greater_than.group_role;
      const comparisonMapping = mappingsByRole.get(comparisonRole);

      if (comparisonMapping) {
        const comparisonValue = parseFloat(
          String(configValues.value[comparisonMapping.measurement_point.id])
        );
        const currentNumeric = parseFloat(String(currentValue));

        if (!isNaN(currentNumeric) && !isNaN(comparisonValue) && currentNumeric <= comparisonValue) {
          fieldErrors.push(
            rules.message ||
            `${registerMapping.register_template.label} must be greater than ${comparisonMapping.register_template.label}`
          );
        }
      }
    }

    return fieldErrors;
  }

  function validateAll(): string[] {
    const validationErrors: string[] = [];
    const groups = groupMappingsByName(allRegisterMappings.value);

    groups.forEach((groupMappings, groupName) => {
      const mappingsByRole = buildRoleMapping(groupMappings, groupName);

      groupMappings.forEach((registerMapping) => {
        if (!isVisible(registerMapping)) return;

        const fieldErrors = validateField(registerMapping, mappingsByRole);
        validationErrors.push(...fieldErrors);
      });

      const mappingsWithOneOfRequired = groupMappings.filter(
        (registerMapping) => registerMapping.register_template.validation_rules?.one_of_required
      );

      if (mappingsWithOneOfRequired.length > 0) {
        const rules = mappingsWithOneOfRequired[0].register_template.validation_rules!;
        const requiredRoles = rules.one_of_required!;

        const hasAnyValue = requiredRoles.some(role => {
          const registerMapping = mappingsByRole.get(role);
          if (!registerMapping) return false;

          const value = configValues.value[registerMapping.measurement_point.id];
          return value !== null && value !== '' && value !== undefined;
        });

        if (!hasAnyValue) {
          validationErrors.push(
            rules.message ||
            `At least one of these fields is required: ${requiredRoles.join(', ')}`
          );
        }
      }
    });

    return validationErrors;
  }

  function validate() {
    errors.value = validateAll();
  }

  const hasErrors = computed(() => errors.value.length > 0);

  watch(
    configValues,
    () => validate(),
    { deep: true }
  );

  return {
    errors,
    hasErrors,
    validate,
    validateField
  };
}
