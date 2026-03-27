<template>
  <!-- Command buttons per group -->
  <div
    v-for="cmdGroup in commandGroups"
    :key="cmdGroup.groupName"
    class="quick-actions__commands d-flex flex-wrap gap-1 mb-2">
    <CButton
      v-for="action in cmdGroup.actions"
      :key="action.enumKey"
      :color="buttonColor(action.label)"
      variant="outline"
      size="sm"
      :disabled="sending !== null"
      class="quick-actions__btn"
      @click="handleCommandClick(cmdGroup, action)">
      <CSpinner
        v-if="sending === `cmd:${cmdGroup.commandMapping.measurement_point.id}:${action.enumKey}`"
        size="sm" />
      <span v-else>{{ action.label }}</span>
    </CButton>
  </div>

  <!-- Feature toggles -->
  <div
    v-if="enabledFeatureToggles.length > 0"
    class="quick-actions__toggles d-flex flex-wrap align-items-center gap-2 mb-2">
    <span class="small text-body-secondary">Features:</span>
    <CBadge
      v-for="toggle in enabledFeatureToggles"
      :key="toggle.groupName"
      :color="toggle.isEnabled ? 'success' : 'secondary'"
      class="quick-actions__toggle-badge"
      role="button"
      :title="toggle.isEnabled ? `Disable ${toggle.groupLabel}` : `Enable ${toggle.groupLabel}`"
      @click="handleToggleClick(toggle)">
      {{ toggle.groupLabel }}
      <span class="ms-1">{{ toggle.isEnabled ? '✓' : '○' }}</span>
    </CBadge>
  </div>

  <!-- Emergency stop -->
  <div
    v-if="emergencyStop"
    class="quick-actions__estop mt-1">
    <CButton
      v-if="!emergencyStop.isActive"
      color="danger"
      size="sm"
      class="w-100"
      :disabled="sending !== null"
      @click="handleEmergencyStop(true)">
      <CSpinner v-if="sending === 'estop'" size="sm" class="me-1" />
      Emergency Stop
    </CButton>
    <CButton
      v-else
      color="danger"
      variant="outline"
      size="sm"
      class="w-100"
      :disabled="sending !== null"
      @click="handleEmergencyStop(false)">
      <CSpinner v-if="sending === 'clear_estop'" size="sm" class="me-1" />
      Clear Emergency Stop
    </CButton>
  </div>

  <!-- Params modal (shared by commands and toggles) -->
  <CommandParamsModal
    :visible="paramsModalVisible"
    :title="paramsModalTitle"
    :param-mappings="paramsModalMappings"
    :all-mappings="props.mappings"
    @close="paramsModalVisible = false"
    @confirm="handleParamsConfirm" />
</template>

<script lang="ts" setup>
  import { computed, ref, reactive, toRef } from 'vue';
  import type { ConfigValues } from '@/composables/useConfigurationValues';
  import type { RegisterMapping } from '@/types/plc';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { OmGroupNameOrSlot } from '@/types/operationMode';
  import {
    useQuickActions,
    type CommandGroup,
    type CommandAction,
    type FeatureToggle,
  } from '@/composables/useQuickActions';
  import CommandParamsModal from './CommandParamsModal.vue';

  const props = defineProps<{
    mappings: RegisterMapping[];
    groupLabels: Record<OmGroupNameOrSlot | string, string>;
  }>();

  const emit = defineEmits<{
    (e: 'write', measurementPointId: MeasurementPoint['id'], value: NonNullable<MeasurementPoint['last_value']>): void;
    (e: 'bulk-write', updates: { measurement_point_id: MeasurementPoint['id']; value: NonNullable<MeasurementPoint['last_value']> }[]): void;
  }>();

  // Config values track current state for toggle enabled detection
  const configValues = reactive<ConfigValues>({});
  for (const rm of props.mappings) {
    configValues[rm.measurement_point.id] = rm.measurement_point.last_value;
  }

  const {
    commandGroups,
    featureToggles,
    emergencyStop,
  } = useQuickActions(
    toRef(props, 'mappings'),
    toRef(props, 'groupLabels'),
    configValues
  );

  const enabledFeatureToggles = computed(() => {
    return featureToggles.value.filter((t) => t.isEnabled);
  });

  // ── Sending state ──

  const sending = ref<string | null>(null);

  function clearSending(key: string) {
    setTimeout(() => {
      if (sending.value === key)
        sending.value = null;
    }, 1500);
  }

  // ── Button color heuristic (derived from enum label text) ──

  function buttonColor(label: string): string {
    const lower = label.toLowerCase();
    if (lower.includes('off') || lower === 'release' || lower === 'auto')
      return 'secondary';

    if (lower.includes('timed'))
      return 'info';

    if (lower.includes('on') || lower === 'start' || lower === 'run')
      return 'success';

    return 'primary';
  }

  // ── Params modal state ──
  //
  // Unified for both commands and toggles:
  // pendingFinalWrite is the register write that happens AFTER params are confirmed.
  // For commands: write the command enum value.
  // For toggles: write enabled = 1.

  type PendingFinalWrite = {
    measurementPointId: number;
    value: string | number;
  };

  const paramsModalVisible = ref(false);
  const paramsModalTitle = ref('');
  const paramsModalMappings = ref<RegisterMapping[]>([]);
  const pendingFinalWrite = ref<PendingFinalWrite | null>(null);

  function openParamsModal(
    title: string,
    paramMappings: RegisterMapping[],
    finalWrite: PendingFinalWrite
  ) {
    paramsModalTitle.value = title;
    paramsModalMappings.value = paramMappings;
    pendingFinalWrite.value = finalWrite;
    paramsModalVisible.value = true;
  }

  function handleParamsConfirm(paramValues: Record<number, string | number>) {
    if (!pendingFinalWrite.value)
      return;

    const updates: { measurement_point_id: number; value: string | number }[] = [];

    // Param writes first
    for (const [mpIdStr, value] of Object.entries(paramValues)) {
      updates.push({ measurement_point_id: Number(mpIdStr), value });
    }

    // Final write (command or enable) last
    updates.push({
      measurement_point_id: pendingFinalWrite.value.measurementPointId,
      value: pendingFinalWrite.value.value,
    });

    emit('bulk-write', updates);

    const key = `cmd:${pendingFinalWrite.value.measurementPointId}:${pendingFinalWrite.value.value}`;
    sending.value = key;
    clearSending(key);

    paramsModalVisible.value = false;
    pendingFinalWrite.value = null;
  }

  // ── Command handling ──

  function handleCommandClick(group: CommandGroup, action: CommandAction) {
    if (action.paramMappings.length > 0) {
      openParamsModal(action.label, action.paramMappings, {
        measurementPointId: group.commandMapping.measurement_point.id,
        value: action.enumKey,
      });
      return;
    }

    const key = `cmd:${group.commandMapping.measurement_point.id}:${action.enumKey}`;
    sending.value = key;
    emit('write', group.commandMapping.measurement_point.id, action.enumKey);
    clearSending(key);
  }

  // ── Feature toggle handling ──

  function handleToggleClick(toggle: FeatureToggle) {
    if (toggle.isEnabled) {
      emit('write', toggle.enabledMapping.measurement_point.id, 0);
      return;
    }

    if (toggle.paramMappings.length > 0) {
      openParamsModal(`Enable ${toggle.groupLabel}`, toggle.paramMappings, {
        measurementPointId: toggle.enabledMapping.measurement_point.id,
        value: 1,
      });
      return;
    }

    emit('write', toggle.enabledMapping.measurement_point.id, 1);
  }

  // ── Emergency stop ──

  function handleEmergencyStop(activate: boolean) {
    if (!emergencyStop.value)
      return;

    const key = activate ? 'estop' : 'clear_estop';
    sending.value = key;
    emit('write', emergencyStop.value.mapping.measurement_point.id, activate ? 1 : 0);
    clearSending(key);
  }
</script>

<style scoped>
  .quick-actions__btn {
    flex: 1 1 0;
    min-width: 0;
    font-size: 0.75rem;
    font-weight: 600;
    white-space: nowrap;
    padding: 0.3rem 0.5rem;
  }

  .quick-actions__toggle-badge {
    cursor: pointer;
    font-size: 0.65rem;
    font-weight: 600;
    transition: opacity 0.15s;
  }

  .quick-actions__toggle-badge:hover {
    opacity: 0.8;
  }
</style>
