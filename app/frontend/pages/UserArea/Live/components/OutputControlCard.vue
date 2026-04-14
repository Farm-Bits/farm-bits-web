<template>
  <div
    class="mp-card"
    :class="{
      'mp-card--alarm': isAlarm,
      'mp-card--warning': isWarning,
      'mp-card--estop': hasActiveEstop,
    }"
    @click="emit('analytics', measurementPoint)">
    <!-- Header: status dot + name + alarm badge -->
    <div class="d-flex align-items-start justify-content-between">
      <div class="d-flex align-items-center gap-2 mb-1">
        <span
          class="status-dot"
          :class="statusDotClass"
          :title="statusTooltip" />
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
        :alarmState="measurementPoint.alarm_state"
        placeholder="No data"
        size="default" />
      <p class="text-body-secondary small">({{ statusLabels }})</p>
    </div>

    <!-- OM Status: enum statuses from read-only status registers -->
    <!-- <div
      v-if="statusBadges.length > 0"
      class="mp-card__om-status d-flex flex-wrap align-items-center gap-2 mb-2">
      <template v-for="badge in statusBadges" :key="badge.label">
        <CBadge :color="badge.color" size="sm">{{ badge.label }}</CBadge>
      </template>
    </div> -->

    <!-- Quick actions (loaded from OM config endpoint) -->
    <div v-if="omConfigLoaded" class="mp-card__actions">
      <QuickActions
        :mappings="omRegisterMappings"
        :group-labels="omGroupLabels"
        @write="handleWrite"
        @bulk-write="handleBulkWrite" />
    </div>

    <!-- Loading indicator while fetching -->
    <div v-else-if="omConfigLoading" class="text-center py-2">
      <CSpinner size="sm" color="secondary" />
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { ref, computed, onMounted } from 'vue';
  import axios from 'axios';
  import RelativeTime from '@/components/RelativeTime.vue';
  import ValueDisplay from '@/components/ValueDisplay.vue';
  import StatusDisplay from '@/components/OperationMode/features/StatusDisplay.vue';
  import QuickActions from './QuickActions.vue';
  import usePermissions from '@/composables/usePermissions';
  import { useApiCall } from '@/composables/useApi';
  import type { LiveMeasurementPoint, OperationModeConfigResponse } from '@/types/analytics';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { RegisterMapping } from '@/types/plc';
  import type { OmGroupNameOrSlot } from '@/types/operationMode';
  import { ROUTES } from '@/types/permissions';
  import { iconMap } from '@/assets/icons/measurement';

  const { measurementPoint, omStatuses } = defineProps<{
    measurementPoint: LiveMeasurementPoint;
    omStatuses: LiveMeasurementPoint[];
  }>();

  const emit = defineEmits<{
    (e: 'analytics', mp: LiveMeasurementPoint): void;
    (e: 'configure', mp: LiveMeasurementPoint): void;
    (e: 'write', measurementPointId: MeasurementPoint['id'], value: NonNullable<MeasurementPoint['last_value']>): void;
    (e: 'bulk-write', anchorMpId: MeasurementPoint['id'], updates: { measurement_point_id: MeasurementPoint['id']; value: NonNullable<MeasurementPoint['last_value']> }[]): void;
  }>();

  const { permissions } = usePermissions();
  const { execute } = useApiCall();

  // ── OM config data (fetched on mount) ──

  const omConfigLoading = ref(false);
  const omConfigLoaded = ref(false);
  const omRegisterMappings = ref<RegisterMapping[]>([]);
  const omGroupLabels = ref<Record<OmGroupNameOrSlot | string, string>>({});

  onMounted(async () => {
    await fetchOmConfig();
  });

  async function fetchOmConfig() {
    omConfigLoading.value = true;
    const configPath = ROUTES.measurement_points_operation_mode_config.path
      .replace(':id', String(measurementPoint.id));

    const { success, data } = await execute<OperationModeConfigResponse>(
      () => axios.get(configPath)
    );

    if (success) {
      omRegisterMappings.value = data.register_mappings;
      omGroupLabels.value = data.group_labels;
      omConfigLoaded.value = true;
    }
    omConfigLoading.value = false;
  }

  // ── Public: patch local mappings after successful writes ──
  //
  // Called by parent with updated MP data from write responses.
  // Patches measurement_point.last_value/last_value_at in-place
  // so QuickActions sees fresh configValues via its watcher.

  function updateMappings(updates: Pick<MeasurementPoint, 'id' | 'last_value' | 'last_value_at'>[]) {
    for (const update of updates) {
      const rm = omRegisterMappings.value.find(
        (m) => m.measurement_point.id === update.id
      );
      if (rm) {
        rm.measurement_point.last_value = update.last_value;
        rm.measurement_point.last_value_at = update.last_value_at;
      }
    }
  }

  defineExpose({ updateMappings });

  // ── Status display (from omStatuses prop — available immediately) ──

  const statusBadges = computed<{ label: string; color: string }[]>(() => {
    const badges: { label: string; color: string }[] = [];

    for (const s of omStatuses) {
      // Only show read-only status registers with enum values
      if (s.register_template.read_only !== true)
        continue;

      if (s.register_template.category !== 'operation_mode_status')
        continue;

      if (s.register_template.value_format === 'enum' && s.register_template.enum_values && s.last_value !== null) {
        const label = s.register_template.enum_values[String(s.last_value)];
        if (label)
          badges.push({ label, color: 'info' });
      }
    }

    return badges;
  });

  const statusLabels = computed(() => {
    return statusBadges.value.map((s) => s.label).join(', ');
  });

  // Emergency stop detection from status registers
  const hasActiveEstop = computed(() =>
    omStatuses.some(s =>
      s.register_template.group_role === 'emergency_stop' &&
      String(s.last_value) === '1'
    )
  );

  // ── Card styling ──

  const isAlarm = computed(() =>
    measurementPoint.alarm_state === 'alarm_low' ||
    measurementPoint.alarm_state === 'alarm_high'
  );

  const isWarning = computed(() =>
    measurementPoint.alarm_state === 'warning_low' ||
    measurementPoint.alarm_state === 'warning_high'
  );

  const statusDotClass = computed(() => {
    if (hasActiveEstop.value)
      return 'status-dot--alarm';

    if (!measurementPoint.last_value_at)
      return 'status-dot--unknown';

    const lastAt = new Date(measurementPoint.last_value_at);
    const diffMs = Date.now() - lastAt.getTime();
    const fiveMinutes = 5 * 60 * 1000;

    if (isAlarm.value)
      return 'status-dot--alarm';

    if (isWarning.value)
      return 'status-dot--warning';

    if (diffMs > fiveMinutes)
      return 'status-dot--stale';

    return 'status-dot--online';
  });

  const statusTooltip = computed(() => {
    if (hasActiveEstop.value)
      return 'Emergency Stop Active';

    const state = measurementPoint.alarm_state;
    if (!state || state === 'normal')
      return 'Normal';

    return state.replace('_', ' ').replace(/\b\w/g, (c) => c.toUpperCase());
  });

  const alarmBadge = computed<{ color: string; label: string } | null>(() => {
    if (hasActiveEstop.value)
      return { color: 'danger', label: 'E-STOP' };

    const state = measurementPoint.alarm_state;
    if (!state || state === 'normal')
      return null;

    const badges: Record<string, { color: string; label: string }> = {
      alarm_low: { color: 'danger', label: 'Alarm Low' },
      alarm_high: { color: 'danger', label: 'Alarm High' },
      warning_low: { color: 'warning', label: 'Warning Low' },
      warning_high: { color: 'warning', label: 'Warning High' },
    };

    return badges[state] ?? null;
  });

  // ── Write handlers ──

  function handleWrite(measurementPointId: MeasurementPoint['id'], value: NonNullable<MeasurementPoint['last_value']>) {
    emit('write', measurementPointId, value);
  }

  function handleBulkWrite(updates: { measurement_point_id: MeasurementPoint['id']; value: NonNullable<MeasurementPoint['last_value']> }[]) {
    emit('bulk-write', measurementPoint.id, updates);
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

  .status-dot--online {
    background-color: #10b981;
    animation: pulse 2s ease-in-out infinite;
  }

  .status-dot--stale {
    background-color: #f59e0b;
  }

  .status-dot--unknown {
    background-color: #9ca3af;
  }

  .status-dot--alarm {
    background-color: #ef4444;
    animation: blink 1s ease-in-out infinite;
  }

  .status-dot--warning {
    background-color: #f59e0b;
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
