<template>
  <div>
    <!-- Enable toggle -->
    <div class="d-flex align-items-center gap-2 mb-3">
      <CFormSwitch
        :model-value="isEnabled"
        @update:model-value="handleToggle" />
      <span :class="isEnabled ? 'fw-semibold' : 'text-body-secondary'">
        {{ isEnabled ? 'Enabled' : 'Disabled' }}
      </span>
    </div>

    <template v-if="isEnabled">
      <p class="text-body-secondary small mb-3">
        When active, the output can only be ON during this window.
      </p>

      <!-- Start time (sun reference composite) -->
      <div class="row g-3 mb-3">
        <div class="col-6">
          <RegisterField
            v-if="startRefMapping"
            :model-value="configValues[startRefMapping.measurement_point.id]"
            :register-mapping="startRefMapping"
            :is-editing="true"
            @update:model-value="emitChange(startRefMapping.measurement_point.id, $event)" />
        </div>
        <div class="col-6">
          <RegisterField
            v-if="startTimeOrOffsetMapping"
            :model-value="configValues[startTimeOrOffsetMapping.measurement_point.id]"
            :register-mapping="startTimeOrOffsetMapping"
            :is-editing="true"
            @update:model-value="emitChange(startTimeOrOffsetMapping.measurement_point.id, $event)" />
        </div>
      </div>

      <!-- End time (sun reference composite) -->
      <div class="row g-3 mb-3">
        <div class="col-6">
          <RegisterField
            v-if="endRefMapping"
            :model-value="configValues[endRefMapping.measurement_point.id]"
            :register-mapping="endRefMapping"
            :is-editing="true"
            @update:model-value="emitChange(endRefMapping.measurement_point.id, $event)" />
        </div>
        <div class="col-6">
          <RegisterField
            v-if="endTimeOrOffsetMapping"
            :model-value="configValues[endTimeOrOffsetMapping.measurement_point.id]"
            :register-mapping="endTimeOrOffsetMapping"
            :is-editing="true"
            @update:model-value="emitChange(endTimeOrOffsetMapping.measurement_point.id, $event)" />
        </div>
      </div>

      <!-- Days bitmask -->
      <div
        v-if="daysMapping"
        class="mb-3">
        <RegisterField
          :model-value="configValues[daysMapping.measurement_point.id]"
          :register-mapping="daysMapping"
          :is-editing="true"
          @update:model-value="emitChange(daysMapping.measurement_point.id, $event)" />
      </div>

      <!-- Any extra fields beyond known roles -->
      <div
        v-for="rm in extraMappings"
        :key="rm.measurement_point.id"
        class="mb-2">
        <RegisterField
          :model-value="configValues[rm.measurement_point.id]"
          :register-mapping="rm"
          :is-editing="true"
          @update:model-value="emitChange(rm.measurement_point.id, $event)" />
      </div>
    </template>
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

  const emit = defineEmits<{
    (e: 'value-change', measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']): void;
  }>();

  const mappingsRef = computed(() => mappings);
  const groupName = vueRef(OM_GROUPS.window);
  const { mpForRole, mappingForRole, mappingsExcept, getValue } = useGroupRegisters(mappingsRef, groupName);

  // ── State ────────────────────────────────────────

  const isEnabled = computed(() => {
    const mpId = mpForRole(OM_ROLES.enabled)?.id;
    if (!mpId)
      return false;

    return String(configValues[mpId]) === '1';
  });

  // ── Start time: show time_of_day when ref=Fixed, offset when ref=Sunrise/Sunset

  const startRefMapping = computed(() => mappingForRole(OM_ROLES.startRef));

  const isStartFixed = computed(() => {
    const mpId = mpForRole(OM_ROLES.startRef)?.id;
    if (!mpId)
      return true;

    return String(configValues[mpId]) === '0';
  });

  const startTimeOrOffsetMapping = computed(() => {
    if (isStartFixed.value) {
      return mappingForRole(OM_ROLES.startTime);
    }
    return mappingForRole(OM_ROLES.startOffset);
  });

  // ── End time: same pattern

  const endRefMapping = computed(() => mappingForRole(OM_ROLES.endRef));

  const isEndFixed = computed(() => {
    const mpId = mpForRole(OM_ROLES.endRef)?.id;
    if (!mpId)
      return true;

    return String(configValues[mpId]) === '0';
  });

  const endTimeOrOffsetMapping = computed(() => {
    if (isEndFixed.value)
      return mappingForRole(OM_ROLES.endTime);

    return mappingForRole(OM_ROLES.endOffset);
  });

  // ── Days + extras

  const daysMapping = computed(() => mappingForRole(OM_ROLES.days));

  const knownRoles = [
    OM_ROLES.enabled,
    OM_ROLES.startRef, OM_ROLES.startTime, OM_ROLES.startOffset,
    OM_ROLES.endRef, OM_ROLES.endTime, OM_ROLES.endOffset,
    OM_ROLES.days,
  ];

  const extraMappings = computed(() => mappingsExcept(...knownRoles));

  // ── Handlers ─────────────────────────────────────

  function handleToggle(value: boolean) {
    const mp = mpForRole(OM_ROLES.enabled);
    if (mp)
      emit('value-change', mp.id, value ? 1 : 0);
  }

  function emitChange(mpId: MeasurementPoint['id'], value: MeasurementPoint['last_value']) {
    emit('value-change', mpId, value);
  }
</script>
