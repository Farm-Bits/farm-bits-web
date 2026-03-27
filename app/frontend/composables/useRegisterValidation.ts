import { computed, ref, watch, type Ref } from 'vue';
import type { RegisterMapping, ValidationRules } from '@/types/plc';
import { normalizeValue, buildRoleMapping, groupMappingsByName } from '@/utils/registerUtils';
import type { ConfigValues } from './useConfigurationValues';

export function useRegisterValidation(
  allRegisterMappings: Ref<RegisterMapping[]>,
  configValues: Ref<ConfigValues>,
  isVisible: (registerMapping: RegisterMapping) => boolean
) {
  const errors = ref<string[]>([]);

  function isEmpty(value: unknown) {
    return value === null || value === '' || value === undefined;
  }

  function getValue(mapping: RegisterMapping) {
    return configValues.value[mapping.measurement_point.id];
  }

  function getNumericValue(mapping: RegisterMapping) {
    return parseFloat(String(getValue(mapping)));
  }

  function compare(
    controllerValue: unknown,
    expectedValue: unknown,
    type: 'equals' | 'not_equals'
  ) {
    const normalizedController = normalizeValue(controllerValue);
    const normalizedExpected = normalizeValue(expectedValue);

    return type === 'equals'
      ? normalizedController === normalizedExpected
      : normalizedController !== normalizedExpected;
  }

  function validateRequiredWhen(
    registerMapping: RegisterMapping,
    rules: ValidationRules,
    mappingsByRole: Map<string, RegisterMapping>
  ) {
    const result: string[] = [];
    const condition = rules.required_when;

    if (!condition)
      return result;

    const controller = mappingsByRole.get(condition.group_role);
    if (!controller)
      return result;

    const comparisonType = condition.equals ? 'equals' : 'not_equals';
    const expectedValue = condition.equals ?? condition.not_equals;

    if (
      compare(getValue(controller), expectedValue, comparisonType) &&
      isEmpty(getValue(registerMapping))
    ) {
      result.push(
        rules.message ||
        `${registerMapping.register_template.label} is required when ${controller.register_template.label} is ${expectedValue}`
      );
    }

    return result;
  }

  function validateRequiredWhenAny(
    registerMapping: RegisterMapping,
    rules: ValidationRules,
    mappingsByRole: Map<string, RegisterMapping>
  ) {
    const result: string[] = [];

    rules.required_when_any?.forEach(condition => {
      const controller = mappingsByRole.get(condition.group_role);
      if (!controller)
        return;

      const comparisonType = condition.equals ? 'equals' : 'not_equals';
      const expectedValue = condition.equals ?? condition.not_equals;

      if (
        compare(getValue(controller), expectedValue, comparisonType) &&
        isEmpty(getValue(registerMapping))
      ) {
        result.push(
          rules.message ||
          `${registerMapping.register_template.label} is required when ${controller.register_template.label} is ${expectedValue}`
        );
      }
    });

    return result;
  }

  function validateLessThan(
    registerMapping: RegisterMapping,
    rules: ValidationRules,
    mappingsByRole: Map<string, RegisterMapping>
  ) {
    const condition = rules.less_than;
    if (!condition)
      return [];

    const comparison = mappingsByRole.get(condition.group_role);
    if (!comparison)
      return [];

    const current = getNumericValue(registerMapping);
    const target = getNumericValue(comparison);

    if (!isNaN(current) && !isNaN(target) && current >= target) {
      return [
        rules.message ||
        `${registerMapping.register_template.label} must be less than ${comparison.register_template.label}`
      ];
    }

    return [];
  }

  function validateGreaterThan(
    registerMapping: RegisterMapping,
    rules: ValidationRules,
    mappingsByRole: Map<string, RegisterMapping>
  ) {
    const condition = rules.greater_than;
    if (!condition)
      return [];

    const comparison = mappingsByRole.get(condition.group_role);
    if (!comparison)
      return [];

    const current = getNumericValue(registerMapping);
    const target = getNumericValue(comparison);

    if (!isNaN(current) && !isNaN(target) && current <= target) {
      return [
        rules.message ||
        `${registerMapping.register_template.label} must be greater than ${comparison.register_template.label}`
      ];
    }

    return [];
  }

  function validateField(
    registerMapping: RegisterMapping,
    mappingsByRole: Map<string, RegisterMapping>
  ) {
    const rules = registerMapping.register_template.validation_rules;
    if (!rules)
      return [];

    return [
      ...validateRequiredWhen(registerMapping, rules, mappingsByRole),
      ...validateRequiredWhenAny(registerMapping, rules, mappingsByRole),
      ...validateLessThan(registerMapping, rules, mappingsByRole),
      ...validateGreaterThan(registerMapping, rules, mappingsByRole)
    ];
  }

  function validateOneOfRequired(
    groupMappings: RegisterMapping[],
    mappingsByRole: Map<string, RegisterMapping>
  ) {
    const mappingsWithRule = groupMappings.filter(
      (m) => m.register_template.validation_rules?.one_of_required
    );

    if (!mappingsWithRule.length)
      return [];

    const rules = mappingsWithRule[0].register_template.validation_rules!;
    const requiredRoles = rules.one_of_required!;

    const hasAnyValue = requiredRoles.some((role) => {
      const mapping = mappingsByRole.get(role);
      return mapping && !isEmpty(getValue(mapping));
    });

    if (!hasAnyValue) {
      return [
        rules.message ||
        `At least one of these fields is required: ${requiredRoles.join(', ')}`
      ];
    }

    return [];
  }

  function validateAll() {
    const validationErrors: string[] = [];
    const groups = groupMappingsByName(allRegisterMappings.value);

    groups.forEach((groupMappings, groupName) => {
      const mappingsByRole = buildRoleMapping(groupMappings, groupName);

      groupMappings.forEach((registerMapping) => {
        if (!isVisible(registerMapping))
          return;

        validationErrors.push(
          ...validateField(registerMapping, mappingsByRole)
        );
      });

      validationErrors.push(
        ...validateOneOfRequired(groupMappings, mappingsByRole)
      );
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
