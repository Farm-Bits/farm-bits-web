import { reactive, ref, type Ref } from 'vue';
import type { RegisterMapping } from '@/types/plc';
import type { MeasurementPoint } from '@/types/measurementPoint';

export type ConfigValues = Record<MeasurementPoint['id'], MeasurementPoint['last_value']>;

export function useConfigurationValues(configRegisterMappings: Ref<RegisterMapping[]>) {
  const userEditedFields = ref<Set<string>>(new Set());
  const configValues = reactive<ConfigValues>({});

  function initializeValues() {
    configRegisterMappings.value.forEach((registerMapping) => {
      configValues[registerMapping.measurement_point.id] =
        registerMapping.measurement_point.last_value ?? null;
    });
  }

  function handleValueChange(
    measurementPointId: MeasurementPoint['id'],
    value: MeasurementPoint['last_value']
  ) {
    configValues[measurementPointId] = value;
    markFieldEdited(`config.${measurementPointId}`);
  }

  function markFieldEdited(fieldPath: string) {
    userEditedFields.value.add(fieldPath);
  }

  function resetEditTracking() {
    userEditedFields.value.clear();
  }

  function isFieldEdited(fieldPath: string): boolean {
    return userEditedFields.value.has(fieldPath);
  }

  function getConfigurationUpdates(): Array<{
    measurement_point_id: number;
    value: MeasurementPoint['last_value'];
  }> {
    return Object.entries(configValues)
      .filter(([id]) => userEditedFields.value.has(`config.${id}`))
      .map(([id, value]) => ({
        measurement_point_id: parseInt(id),
        value
      }));
  }

  function reinitialize() {
    Object.keys(configValues).forEach(key => {
      delete configValues[key as unknown as number];
    });
    initializeValues();
  }

  return {
    configValues,
    userEditedFields,
    initializeValues,
    handleValueChange,
    markFieldEdited,
    resetEditTracking,
    isFieldEdited,
    getConfigurationUpdates,
    reinitialize
  };
}
