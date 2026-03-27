<template>
  <div class="device-configuration-tab py-3">
    <div v-if="!hasConfiguration" class="text-center py-5 text-muted">
      <CIcon icon="cilCog" size="3xl" class="mb-3" />
      <p>No device configuration options available for this interface.</p>
    </div>

    <div v-else>
      <CAlert v-if="validationErrors.length > 0" color="danger" class="mb-4">
        <strong>Configuration Errors:</strong>
        <ul class="mb-0 mt-2">
          <li v-for="(error, index) in validationErrors" :key="index">
            {{ error }}
          </li>
        </ul>
      </CAlert>

      <div v-for="group in configurationGroups" :key="group.name || 'ungrouped'" class="mb-4">
        <h6 class="text-muted border-bottom pb-2 mb-3">
          {{ formatGroupName(group.name) }}
        </h6>

        <div class="row g-3">
          <div
            v-for="registerMapping in group.registerMappings"
            :key="registerMapping.register_template.id"
            :class="getConfigFieldClass(registerMapping)"
            v-show="isConfigurationVisible(registerMapping)">
            <CFormLabel class="fw-semibold d-flex align-items-center gap-2">
              {{ registerMapping.register_template.name }}
              <CTooltip
                v-if="registerMapping.register_template.description"
                :content="registerMapping.register_template.description">
                <template #toggler="{ on }">
                  <CIcon v-on="on" icon="cilInfo" size="sm" class="text-muted" />
                </template>
              </CTooltip>
            </CFormLabel>
            <RegisterField
              v-model="modelValue[registerMapping.measurement_point.id]"
              :registerMapping="registerMapping"
              :isEditing="true"
              @update:model-value="handleValueChange(registerMapping.measurement_point.id, $event)" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import RegisterField from '@/components/RegisterField.vue';
  import type { ConfigValues } from '@/composables/useConfigurationValues';
  import { formatGroupName, getConfigFieldClass } from '@/utils/registerUtils';
  import type { RegisterMapping } from '@/types/plc';
  import type { MeasurementPoint } from '@/types/measurementPoint';

  const {
    modelValue,
    configurationRegisterMappings,
    validationErrors,
    isConfigurationVisible
  } = defineProps<{
    modelValue: ConfigValues;
    configurationRegisterMappings: RegisterMapping[];
    validationErrors: string[];
    isConfigurationVisible: (registerMapping: RegisterMapping) => boolean;
  }>();

  const emit = defineEmits<{
    (eventName: 'update:modelValue', value: ConfigValues): void;
    (eventName: 'value-change', measurementPointId: number, value: MeasurementPoint['last_value']): void;
  }>();

  const hasConfiguration = computed(() => configurationRegisterMappings.length > 0);

  const configurationGroups = computed(() => {
    const groups = new Map<string | null, RegisterMapping[]>();

    configurationRegisterMappings.forEach((registerMapping) => {
      const groupName = registerMapping.register_template.group_name;
      if (!groups.has(groupName)) {
        groups.set(groupName, []);
      }
      groups.get(groupName)!.push(registerMapping);
    });

    return Array.from(groups.entries())
      .map(([name, registerMappings]) => ({
        name,
        registerMappings: [...registerMappings].sort((a, b) => a.position - b.position)
      }))
      .sort((a, b) => {
        if (a.name === null)
          return 1;

        if (b.name === null)
          return -1;

        return a.name.localeCompare(b.name);
      });
  });

  function handleValueChange(
    measurementPointId: number,
    value: MeasurementPoint['last_value']
  ) {
    const updated = { ...modelValue, [measurementPointId]: value };
    emit('update:modelValue', updated);
    emit('value-change', measurementPointId, value);
  }
</script>

<style scoped>
  .device-configuration-tab {
    min-height: 300px;
  }
</style>
