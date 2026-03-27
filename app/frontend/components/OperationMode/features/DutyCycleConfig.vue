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

    <!-- Preview bar -->
    <div
      v-if="isEnabled && onDuration > 0 && offDuration > 0"
      class="mb-3">
      <div class="d-flex rounded overflow-hidden" style="height: 24px;">
        <div
          v-for="i in 3"
          :key="i"
          class="d-flex"
          :style="{ flex: 'none', width: `${100 / 3}%` }">
          <div
            class="d-flex align-items-center justify-content-center bg-success-subtle text-success"
            :style="{ flex: onDuration, fontSize: '10px', fontWeight: 600 }">
            {{ activeLabel }}
          </div>
          <div
            class="d-flex align-items-center justify-content-center bg-danger-subtle text-danger"
            :style="{ flex: offDuration, fontSize: '10px', fontWeight: 600 }">
            {{ inactiveLabel }}
          </div>
        </div>
      </div>
      <div class="d-flex justify-content-between mt-1">
        <small class="text-body-secondary">Cycle: {{ formatDuration(onDuration + offDuration) }}</small>
        <small class="text-body-secondary">Duty: {{ dutyPercent }}%</small>
      </div>
    </div>

    <!-- ON/OFF duration fields (known roles, rendered as RegisterField) -->
    <div class="row g-3 mb-3">
      <div
        v-if="onDurationMapping"
        class="col-6">
        <RegisterField
          :register-mapping="onDurationMapping"
          :model-value="configValues[onDurationMapping.measurement_point.id]"
          :isEditing="true"
          @update:model-value="emitChange(onDurationMapping.measurement_point.id, $event)" />
      </div>
      <div
        v-if="offDurationMapping"
        class="col-6">
        <RegisterField
          :register-mapping="offDurationMapping"
          :model-value="configValues[offDurationMapping.measurement_point.id]"
          :isEditing="true"
          @update:model-value="emitChange(offDurationMapping.measurement_point.id, $event)" />
      </div>
    </div>

    <!-- Any additional fields beyond the known roles -->
    <div
      v-for="rm in extraMappings"
      :key="rm.measurement_point.id"
      class="mb-2">
      <RegisterField
        v-model="configValues[rm.measurement_point.id]"
        :register-mapping="rm"
        :isEditing="isEnabled"
        @update:model-value="emitChange(rm.measurement_point.id, $event)" />
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed, ref as vueRef } from 'vue';
  import RegisterField from '@/components/RegisterField.vue';
  import { useGroupRegisters } from '@/composables/useGroupRegisters';
  import { valueConverters } from '@/utils/valueConverters';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { RegisterMapping } from '@/types/plc';
  import { OM_GROUPS, OM_ROLES } from '@/types/operationMode';

  const { mappings, configValues } = defineProps<{
    mappings: RegisterMapping[];
    configValues: Record<number, string | number | null>;
  }>();

  const emit = defineEmits<{
    (e: 'value-change', measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']): void;
  }>();

  const mappingsRef = computed(() => mappings);
  const groupName = vueRef(OM_GROUPS.dutyCycle);
  const { getValue, mpForRole, mappingForRole, mappingsExcept, templateForRole } = useGroupRegisters(mappingsRef, groupName);

  // ── State ────────────────────────────────────────

  const isEnabled = computed(() => {
    const mpId = mpForRole(OM_ROLES.enabled)?.id;
    if (!mpId)
      return false;

    const val = configValues[mpId];
    return String(val) === '1';
  });

  const onDuration = computed(() => {
    const mpId = mpForRole(OM_ROLES.onDuration)?.id;
    if (!mpId)
      return 0;

    return Number(configValues[mpId]) || 0;
  });

  const offDuration = computed(() => {
    const mpId = mpForRole(OM_ROLES.offDuration)?.id;
    if (!mpId)
      return 0;

    return Number(configValues[mpId]) || 0;
  });

  const dutyPercent = computed(() => {
    const total = onDuration.value + offDuration.value;
    if (total === 0)
      return 0;

    return Math.round((onDuration.value / total) * 100);
  });

  // ── Active/Inactive labels from the enabled register ──

  const activeLabel = computed(() => {
    const unit = mpForRole(OM_ROLES.enabled)?.effective_unit ?? null;
    return valueConverters.boolean.toDisplay(1, unit);
  });

  const inactiveLabel = computed(() => {
    const unit = mpForRole(OM_ROLES.enabled)?.effective_unit ?? null;
    return valueConverters.boolean.toDisplay(0, unit);
  });

  // ── Mappings ─────────────────────────────────────

  const onDurationMapping = computed(() => mappingForRole(OM_ROLES.onDuration));
  const offDurationMapping = computed(() => mappingForRole(OM_ROLES.offDuration));

  const extraMappings = computed(() =>
    mappingsExcept(OM_ROLES.enabled, OM_ROLES.onDuration, OM_ROLES.offDuration)
  );

  // ── Handlers ─────────────────────────────────────

  function handleToggle(value: boolean) {
    const mp = mpForRole(OM_ROLES.enabled);
    if (mp)
      emit('value-change', mp.id, value ? 1 : 0);
  }

  function emitChange(measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']) {
    emit('value-change', measurementPointId, value);
  }

  function formatDuration(totalSeconds: number) {
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
