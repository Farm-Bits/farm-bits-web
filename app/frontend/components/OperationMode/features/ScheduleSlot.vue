<template>
  <div
    class="border rounded mb-2"
    :class="isEnabled ? 'border-info-subtle' : ''">
    <!-- Header: toggle + label + collapse arrow -->
    <div
      class="d-flex align-items-center gap-2 px-3 py-2"
      role="button"
      @click="isOpen = !isOpen">
      <CFormSwitch
        :model-value="isEnabled"
        @click.stop
        @update:model-value="handleToggle" />
      <span
        class="flex-grow-1 fw-medium"
        :class="isEnabled ? '' : 'text-body-secondary'">
        {{ label }} {{ slotNumber }}
        <template v-if="!isOpen && isEnabled">
          <small class="text-body-secondary ms-2">{{ summaryText }}</small>
        </template>
      </span>
      <small class="text-body-secondary">{{ isOpen ? '▴' : '▾' }}</small>
    </div>

    <!-- Body: all fields rendered generically -->
    <div
      v-if="isOpen"
      class="px-3 pb-3">
      <!-- Start time: sun reference composite -->
      <div class="row g-3 mb-2">
        <div class="col-6">
          <RegisterField
            v-if="startRefMapping"
            v-model="configValues[startRefMapping.measurement_point.id]"
            :register-mapping="startRefMapping"
            :is-editing="true"
            @update:model-value="emitChange(startRefMapping.measurement_point.id, $event)" />
        </div>
        <div class="col-6">
          <RegisterField
            v-if="startTimeOrOffsetMapping"
            v-model="configValues[startTimeOrOffsetMapping.measurement_point.id]"
            :register-mapping="startTimeOrOffsetMapping"
            :is-editing="true"
            @update:model-value="emitChange(startTimeOrOffsetMapping.measurement_point.id, $event)" />
        </div>
      </div>

      <!-- Remaining fields: generic rendering with visibility -->
      <div
        v-for="rm in visibleRemainingMappings"
        :key="rm.measurement_point.id"
        class="mb-2">
        <RegisterField
          v-model="configValues[rm.measurement_point.id]"
          :register-mapping="rm"
          :is-editing="true"
          @update:model-value="emitChange(rm.measurement_point.id, $event)" />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed, ref } from 'vue';
  import RegisterField from '@/components/RegisterField.vue';
  import { useGroupRegisters } from '@/composables/useGroupRegisters';
  import type { ConfigValues } from '@/composables/useConfigurationValues';
  import type { RegisterMapping } from '@/types/plc';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import { OM_ROLES } from '@/types/operationMode';

  const { mappings, groupName, slotNumber, label, configValues } = defineProps<{
    mappings: RegisterMapping[];
    groupName: string;
    slotNumber: number;
    label: string;
    configValues: ConfigValues;
  }>();

  const emit = defineEmits<{
    (e: 'value-change', measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']): void;
  }>();

  const mappingsRef = computed(() => mappings);
  const groupNameRef = computed(() => groupName);
  const { getValue, mpForRole, mappingForRole, mappingsExcept } = useGroupRegisters(mappingsRef, groupNameRef);

  const isOpen = ref(false);

  // ── State ────────────────────────────────────────

  const isEnabled = computed(() => {
    const mpId = mpForRole(OM_ROLES.enabled)?.id;
    if (!mpId)
      return false;

    return String(configValues[mpId]) === '1';
  });

  // ── Start time: sun reference composite ──────────

  const startRefMapping = computed(() => mappingForRole(OM_ROLES.startRef));

  const isStartFixed = computed(() => {
    const mpId = mpForRole(OM_ROLES.startRef)?.id;
    if (!mpId)
      return true;

    return String(configValues[mpId]) === '0';
  });

  const startTimeOrOffsetMapping = computed(() => {
    if (isStartFixed.value)
      return mappingForRole(OM_ROLES.startTime);

    return mappingForRole(OM_ROLES.startOffset);
  });

  // ── Remaining fields (everything except known layout roles) ──

  const layoutRoles = [
    OM_ROLES.enabled,
    OM_ROLES.startRef, OM_ROLES.startTime, OM_ROLES.startOffset,
  ];

  const remainingMappings = computed(() => mappingsExcept(...layoutRoles));

  const visibleRemainingMappings = computed(() =>
    remainingMappings.value.filter(rm => isVisible(rm))
  );

  // ── Summary for collapsed state ──────────────────

  const summaryText = computed(() => {
    const startRefMpId = mpForRole(OM_ROLES.startRef)?.id;
    const startRefValue = startRefMpId ? String(configValues[startRefMpId] ?? '0') : '0';
    const refTemplate = mappingForRole(OM_ROLES.startRef)?.register_template;
    const refLabel = refTemplate?.enum_values?.[startRefValue] ?? 'Fixed';

    const durationMpId = mpForRole(OM_ROLES.duration)?.id;
    const durationSeconds = durationMpId ? Number(configValues[durationMpId]) || 0 : 0;

    const parts = [refLabel];
    if (durationSeconds > 0)
      parts.push(formatDuration(durationSeconds));

    return parts.join(' · ');
  });

  // ── Handlers ─────────────────────────────────────

  function handleToggle(value: boolean) {
    const mp = mpForRole(OM_ROLES.enabled);
    if (mp)
      emit('value-change', mp.id, value ? 1 : 0);

    if (value)
      isOpen.value = true;
  }

  function emitChange(measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']) {
    emit('value-change', measurementPointId, value);
  }

  function isVisible(rm: RegisterMapping) {
    const conditions = rm.register_template.visibility_conditions;
    if (!conditions)
      return true;

    for (const [controllerRole, expectedValues] of Object.entries(conditions)) {
      const controllerMapping = mappings.find(m =>
        m.register_template.group_name === groupName &&
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

  function formatDuration(totalSeconds: number) {
    const h = Math.floor(totalSeconds / 3600);
    const m = Math.floor((totalSeconds % 3600) / 60);
    if (h > 0)
      return `${h}h ${m}m`;

    return `${m}m`;
  }
</script>
