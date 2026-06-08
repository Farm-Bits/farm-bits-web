<template>
  <div
    class="mp-card"
    :class="{
      'mp-card--estop': hasActiveEstop,
    }"
    @click="emit('analytics', measurementPoint)">
    <!-- Header: status dot + name + alarm badge -->
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
            @click="emit('configure', measurementPoint)">
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

    <!-- Meta: PLC name + interface + last seen -->
    <!-- <div class="mp-card__meta d-flex align-items-center gap-2 mb-2">
      <span class="small text-body-secondary">{{ measurementPoint.plc_name }}</span>
      <span class="small text-body-secondary">·</span>
      <span class="small text-body-secondary">{{ measurementPoint.register_template.name }}</span>
      <span v-if="measurementPoint.last_value_at" class="small text-body-secondary ms-auto">
        <RelativeTime :datetime="measurementPoint.last_value_at" />
      </span>
    </div> -->

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
</template>

<script lang="ts" setup>
  import { computed, toRef } from 'vue';
  import ConnectionStatusIndicator from '@/components/ConnectionStatusIndicator.vue';
  import ValueDisplay from '@/components/ValueDisplay.vue';
  import StatusDisplay from '@/components/OperationMode/features/StatusDisplay.vue';
  import QuickActions from './QuickActions.vue';
  import usePermissions from '@/composables/usePermissions';
  import { useRegisterVisibility } from '@/composables/useRegisterVisibility';
  import { useEmergencyStop } from '@/composables/useEmergencyStop';
  import { getDisplayValue } from '@/utils/valueConverters';
  import type { LiveMeasurementPoint } from '@/types/analytics';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { RegisterMapping } from '@/types/plc';
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

  const emit = defineEmits<{
    (e: 'analytics', mp: LiveMeasurementPoint): void;
    (e: 'configure', mp: LiveMeasurementPoint): void;
    (e: 'write', measurementPointId: MeasurementPoint['id'], value: NonNullable<MeasurementPoint['last_value']>): void;
    (e: 'bulk-write', anchorMpId: MeasurementPoint['id'], updates: { measurement_point_id: MeasurementPoint['id']; value: NonNullable<MeasurementPoint['last_value']> }[]): void;
  }>();

  const { permissions } = usePermissions();
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

  // ── Status display (from omStatuses prop — available immediately) ──

  const statusBadges = computed<{ label: string; color: string }[]>(() => {
    const badges: { label: string; color: string }[] = [];

    for (const s of [ ...interfaceStatuses, ...omStatuses]) {
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

  const statusLabels = computed(() => {
    return statusBadges.value.map((s) => s.label).join(', ');
  });

  // Emergency stop — discovered structurally from the writable e-stop register
  const { emergencyStop } = useEmergencyStop(toRef(() => registerMappings));

  const hasActiveEstop = computed(() => emergencyStop.value?.isActive ?? false);

  // ── Card styling ──

  const statusTooltip = computed(() => {
    if (hasActiveEstop.value)
      return 'Emergency Stop Active';

    return 'Normal';
  });

  const alarmBadge = computed<{ color: string; label: string } | null>(() => {
    if (hasActiveEstop.value)
      return { color: 'danger', label: 'E-STOP' };

    return null;
  });

  // ── Write handlers ──

  function handleWrite(measurementPointId: MeasurementPoint['id'], value: NonNullable<MeasurementPoint['last_value']>) {
    emit('write', measurementPointId, value);
  }

  function handleBulkWrite(updates: { measurement_point_id: MeasurementPoint['id']; value: NonNullable<MeasurementPoint['last_value']> }[]) {
    emit('bulk-write', measurementPoint.id, updates);
  }

  function handleEmergencyStopToggle() {
    if (!emergencyStop.value)
      return;

    emit('write', emergencyStop.value.mapping.measurement_point.id, emergencyStop.value.isActive ? 0 : 1);
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

  .mp-card--alarm {
    border-color: #ef4444;
    background: #fef2f2;
  }

  .mp-card--warning {
    border-color: #f59e0b;
    background: #fffbeb;
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

  .feature-badge {
    font-size: 0.6rem;
  }

  .status-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
  }

  @keyframes blink {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.3; }
  }
</style>
