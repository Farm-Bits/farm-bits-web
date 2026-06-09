<template>
  <div
    class="mp-card"
    :class="{ 'mp-card--estop': hasActiveEstop }"
    @click="emit('analytics', measurementPoint)">
    <!-- Header: status dot + name + alarm badge + options -->
    <div class="d-flex align-items-start justify-content-between">
      <div class="d-flex align-items-center gap-2 mb-1">
        <ConnectionStatusIndicator size="sm" :measurementPoint="measurementPoint" />
        <img
          v-if="measurementPoint.measurement_subtype && measurementPoint.measurement_subtype.icon_key"
          class="w-5 h-5"
          :src="iconMap[measurementPoint.measurement_subtype.icon_key]"
          :alt="measurementPoint.measurement_subtype.name" />
        <span class="mp-card__name">
          {{ measurementPoint.measurement_subtype && !measurementPoint.measurement_subtype.icon_key ?
            `${measurementPoint.measurement_subtype.name} |` : '' }}
          {{ measurementPoint.name }}
        </span>
      </div>
      <CBadge v-if="alarmBadge" :color="alarmBadge.color" size="sm">
        {{ alarmBadge.label }}
      </CBadge>

      <CDropdown v-if="permissions?.measurement_points.operation_mode_config" class="options-dropdown" @click.stop>
        <CDropdownToggle color="light" size="sm" :caret="false">
          <CIcon icon="cilOptions" />
        </CDropdownToggle>
        <CDropdownMenu>
          <CDropdownItem
            v-if="permissions?.measurement_points.operation_mode_config"
            @click="configureVisible = true">
            Configure automation
          </CDropdownItem>
          <CDropdownItem
            v-if="emergencyStop"
            class="text-danger"
            @click="handleEmergencyStopToggle">
            {{ emergencyStop.isActive ? 'Clear Emergency Stop' : 'Emergency Stop' }}
          </CDropdownItem>
        </CDropdownMenu>
      </CDropdown>
    </div>

    <!-- Value display -->
    <div class="flex items-center mb-2 gap-2">
      <ValueDisplay
        :value="measurementPoint.last_value"
        :valueFormat="measurementPoint.register_template.value_format"
        :unit="measurementPoint.effective_unit"
        :enumValues="measurementPoint.register_template.enum_values"
        placeholder="No data"
        size="default" />
      <p v-show="statusLabels != ''" class="text-body-secondary small">({{ statusLabels }})</p>
    </div>

    <!-- Quick actions -->
    <div v-if="omMappings.length > 0" class="mp-card__actions">
      <QuickActions
        :mappings="omMappings"
        :group-labels="omGroupLabels"
        @write="handleWrite"
        @bulk-write="handleBulkWrite" />
    </div>
  </div>

  <ConfigureAutomationModal
    :visible="configureVisible"
    :measurement-point="measurementPoint"
    @close="configureVisible = false"
    @updated="(mps) => emit('updated', mps)" />
</template>

<script lang="ts" setup>
  import { computed, ref, toRef } from 'vue';
  import axios from 'axios';
  import ConnectionStatusIndicator from '@/components/ConnectionStatusIndicator.vue';
  import ValueDisplay from '@/components/ValueDisplay.vue';
  import QuickActions from './QuickActions.vue';
  import ConfigureAutomationModal from './ConfigureAutomationModal.vue';
  import usePermissions from '@/composables/usePermissions';
  import useAuth from '@/composables/useAuth';
  import { useApiCall } from '@/composables/useApi';
  import { useRegisterVisibility } from '@/composables/useRegisterVisibility';
  import { useEmergencyStop } from '@/composables/useEmergencyStop';
  import { getDisplayValue } from '@/utils/valueConverters';
  import type { LiveMeasurementPoint } from '@/types/analytics';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { MeasurementPointConfigResponse, RegisterMapping } from '@/types/plc';
  import type { OmGroupNameOrSlot } from '@/types/operationMode';
  import type { ConfigValues } from '@/composables/useConfigurationValues';
  import { iconMap } from '@/assets/icons/measurement';

  const { measurementPoint, interfaceStatuses, omStatuses, registerMappings, omGroupLabels } = defineProps<{
    measurementPoint: LiveMeasurementPoint;
    interfaceStatuses: LiveMeasurementPoint[];
    omStatuses: LiveMeasurementPoint[];
    registerMappings: RegisterMapping[];
    omGroupLabels: Record<OmGroupNameOrSlot | string, string>;
  }>();

  // The card owns its control interactions and emits the changed measurement
  // points so the host can sync local state. Analytics stays host-owned.
  const emit = defineEmits<{
    (e: 'analytics', mp: LiveMeasurementPoint): void;
    (e: 'updated', measurementPoints: MeasurementPoint[]): void;
  }>();

  const { permissions } = usePermissions();
  const { routePath } = useAuth();
  const { execute } = useApiCall();

  const configureVisible = ref(false);

  const { isVisible } = useRegisterVisibility(
    toRef(() => registerMappings),
    toRef(() => [...omStatuses, ...interfaceStatuses].reduce((acc: ConfigValues, s) => {
      acc[s.id] = s.last_value;
      return acc;
    }, {}))
  );

  const omMappings = computed(() =>
    registerMappings.filter((rm) =>
      rm.register_template.category === 'operation_mode_status' ||
      rm.register_template.category === 'operation_mode_configuration'
    )
  );

  // ── Status display ──

  const statusBadges = computed<{ label: string; color: string }[]>(() => {
    const badges: { label: string; color: string }[] = [];

    for (const s of [...interfaceStatuses, ...omStatuses]) {
      if (s.register_template.read_only !== true)
        continue;

      const statusIsVisible = isVisible({
        register_template: s.register_template,
        measurement_point: s,
        position: s.position
      });
      if (s.last_value !== null && statusIsVisible) {
        const label = getDisplayValue(
          s.last_value,
          s.register_template.value_format,
          {
            unit: s.effective_unit,
            enumValues: s.register_template.enum_values
          }
        );
        if (label)
          badges.push({ label, color: 'info' });
      }
    }

    return badges;
  });

  const statusLabels = computed(() => statusBadges.value.map((s) => s.label).join(', '));

  // ── Emergency stop ──

  const { emergencyStop } = useEmergencyStop(toRef(() => registerMappings));
  const hasActiveEstop = computed(() => emergencyStop.value?.isActive ?? false);

  const alarmBadge = computed<{ color: string; label: string } | null>(() => {
    if (hasActiveEstop.value)
      return { color: 'danger', label: 'E-STOP' };

    return null;
  });

  // ── Control interactions (owned by the card) ──

  async function handleWrite(
    measurementPointId: MeasurementPoint['id'],
    value: NonNullable<MeasurementPoint['last_value']>
  ) {
    const { success, data } = await execute<MeasurementPoint>(
      () => axios.post(routePath('measurement_points_write', { id: measurementPointId }), { value })
    );

    if (success)
      emit('updated', [data]);
  }

  async function handleBulkWrite(
    updates: { measurement_point_id: MeasurementPoint['id']; value: NonNullable<MeasurementPoint['last_value']> }[]
  ) {
    if (updates.length === 0)
      return;

    const { success, data } = await execute<MeasurementPointConfigResponse>(
      () => axios.patch(
        routePath('measurement_points_update', { id: measurementPoint.id }),
        { configuration_updates: updates }
      )
    );

    if (success)
      emit('updated', [data.measurement_point, ...data.sibling_measurement_points]);
  }

  function handleEmergencyStopToggle() {
    if (!emergencyStop.value)
      return;

    handleWrite(emergencyStop.value.mapping.measurement_point.id, emergencyStop.value.isActive ? 0 : 1);
  }
</script>

<style scoped>
  .mp-card {
    padding: 0.75rem;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    transition: box-shadow 0.15s, border-color 0.15s;
    background: #fff;
  }

  .mp-card:hover {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
    border-color: var(--primary-color);
  }

  .mp-card--estop {
    border-color: #ef4444;
    background: #fef2f2;
    animation: estop-pulse 2s ease-in-out infinite;
  }

  @keyframes estop-pulse {
    0%, 100% { border-color: #ef4444; }
    50% { border-color: #ef444466; }
  }

  .mp-card__name {
    font-weight: 600;
    font-size: 0.875rem;
    color: #374151;
  }
</style>
