<template>
  <CContainer fluid class="px-4 py-2">
    <!-- Header -->
    <div class="d-flex align-items-center justify-content-between mb-2">
      <SegmentFilter
        v-model="selectedSegmentId"
        :segments="segments" />
      <div class="d-flex align-items-center gap-2">
        <span v-if="polling.lastPollAt.value" class="small text-body-secondary">
          Updated <RelativeTime :datetime="polling.lastPollAt.value.toISOString()" />
        </span>
      </div>
    </div>

    <!-- Empty state -->
    <div v-if="filteredMeasurementPoints.length === 0" class="text-center py-5">
      <CIcon name="cil-speedometer" size="3xl" class="text-body-secondary mb-3" />
      <h5 class="text-body-secondary">No active measurement points</h5>
      <p class="text-body-secondary">
        There are no active measurement points collecting data for this site.
      </p>
    </div>

    <!-- Segment Accordion -->
    <template v-else>
      <CCard
        v-for="segment in segmentGroups"
        :key="segment.key"
        class="mb-4 shadow-sm">
        <CCardHeader
          class="segment-header"
          role="button"
          @click="toggleSegment(segment.key)">
          <div class="d-flex align-items-center justify-content-between">
            <h6 class="mb-0">
              {{ segment.label }}
            </h6>
            <CIcon
              v-if="openSegments[segment.key]" name="cilChevronTop" size="sm" />
            <CIcon v-else name="cilChevronBottom" size="sm" />
          </div>
        </CCardHeader>
        <CCardBody v-show="openSegments[segment.key]">
          <!-- Sensors Section -->
          <div v-if="segment.sensorMps.length > 0" class="mb-4">
            <div class="d-flex align-items-center mb-3">
              <h6 class="mb-0 text-body-secondary text-uppercase small fw-semibold">
                Sensors
              </h6>
              <button
                class="btn btn-link btn-sm ms-auto p-0 text-body-secondary"
                @click="handleSensorGroupClick(segment)">
                <small>View analytics</small>
              </button>
            </div>
            <div class="row g-3">
              <div
                v-for="mp in segment.sensorMps"
                :key="mp.id"
                class="col-sm-6 col-md-4 col-lg-3">
                <MeasurementCard
                  :measurement-point="mp"
                  :register-mappings="mappingsForInterface(mp)"
                  :interface-statuses="interfaceStatusesForInterface(mp)"
                  :om-statuses="omStatusesForInterface(mp)"
                  :om-group-labels="omGroupLabels"
                  :enable-control="true"
                  @analytics="handleMpClick"
                  @updated="handleUpdated" />
              </div>
            </div>
          </div>

          <!-- Control Section -->
          <div v-if="segment.controlGroups.length > 0">
            <div class="d-flex align-items-center mb-3">
              <h6 class="mb-0 text-body-secondary text-uppercase small fw-semibold">
                Control
              </h6>
            </div>

            <!-- Control sub-groups (Climate Control, Irrigation, etc.) -->
            <div
              v-for="controlGroup in segment.controlGroups"
              :key="controlGroup.key"
              class="mb-3">
              <div class="d-flex align-items-center mb-2">
                <img
                  v-if="controlGroup.icon"
                  :src="controlGroup.icon"
                  :alt="controlGroup.label"
                  class="control-group-icon me-2" />
                <span class="fw-medium small">{{ controlGroup.label }}</span>
              </div>
              <div class="row g-3">
                <div
                  v-for="mp in controlGroup.measurementPoints"
                  :key="mp.id"
                  class="col-sm-6 col-md-4 col-lg-3">
                  <MeasurementCard
                    :measurement-point="mp"
                    :register-mappings="mappingsForInterface(mp)"
                    :interface-statuses="interfaceStatusesForInterface(mp)"
                    :om-statuses="omStatusesForInterface(mp)"
                    :om-group-labels="omGroupLabels"
                    :enable-control="true"
                    @analytics="handleMpClick"
                    @updated="handleUpdated" />
                </div>
              </div>
            </div>
          </div>

          <!-- Fully empty segment -->
          <div
            v-if="segment.sensorMps.length === 0 && segment.controlGroups.length === 0"
            class="text-center py-3 text-body-secondary">
            <small>No active measurement points in this segment.</small>
          </div>
        </CCardBody>
      </CCard>
    </template>

    <!-- Analytics Modal -->
    <MeasurementPointAnalyticsModal
      :visible="analyticsModalVisible"
      :measurement-points="analyticsModalMeasurementPoints"
      @close="analyticsModalVisible = false" />
  </CContainer>
</template>

<script lang="ts" setup>
  import { ref, computed, reactive, watch } from 'vue';
  import axios from 'axios';
  import useAuth from '@/composables/useAuth';
  import { useApiCall } from '@/composables/useApi';
  import { useLivePolling } from '@/composables/useLivePolling';
  import SegmentFilter from '@/components/SegmentFilter.vue';
  import MeasurementPointAnalyticsModal from '@/components/MeasurementPointAnalyticsModal.vue';
  import RelativeTime from '@/components/RelativeTime.vue';
  import MeasurementCard from '@/components/MeasurementCard/index.vue';
  import { ROUTES } from '@/types/permissions';
  import type { MeasurementPoint, MeasurementSubtype } from '@/types/measurementPoint';
  import type { RegisterMapping } from '@/types/plc';
  import type { LiveMeasurementPoint } from '@/types/analytics';
  import { iconMap } from '@/assets/icons/controlGroup';

  type ControlGroupView = {
    key: string;
    label: string;
    icon: string | null;
    position: number;
    measurementPoints: LiveMeasurementPoint[];
  };

  type SegmentGroup = {
    key: string;
    label: string;
    allMps: LiveMeasurementPoint[];
    sensorMps: LiveMeasurementPoint[];
    controlGroups: ControlGroupView[];
    controlMpCount: number;
  };

  type PollResponse = {
    measurement_points: {
      id: MeasurementPoint['id'];
      last_value: MeasurementPoint['last_value'];
      last_value_at: MeasurementPoint['last_value_at'];
      effective_unit: MeasurementPoint['effective_unit'];
    }[];
    interface_statuses: {
      id: MeasurementPoint['id'];
      last_value: MeasurementPoint['last_value'];
      last_value_at: MeasurementPoint['last_value_at'];
      effective_unit: MeasurementPoint['effective_unit'];
    }[];
    operation_mode_statuses: {
      id: MeasurementPoint['id'];
      last_value: MeasurementPoint['last_value'];
      last_value_at: MeasurementPoint['last_value_at'];
      effective_unit: MeasurementPoint['effective_unit'];
    }[];
  };

  const { currentSite, pageProps, routePath } = useAuth<{
    measurement_points: LiveMeasurementPoint[];
    interface_statuses: LiveMeasurementPoint[];
    operation_mode_statuses: LiveMeasurementPoint[];
    operation_mode_configurations: LiveMeasurementPoint[];
    operation_mode_group_labels: Record<string, string>;
    measurement_subtypes: MeasurementSubtype[];
  }>();
  const segments = computed(() => currentSite.value?.segments || []);

  const { execute } = useApiCall();

  const openSegments = reactive<Record<string, boolean>>({});

  // ── Reactive data ───────────────────────────────

  const measurementPoints = ref<LiveMeasurementPoint[]>([...pageProps.value.measurement_points]);
  const interfaceStatuses = ref<LiveMeasurementPoint[]>([...pageProps.value.interface_statuses]);
  const omStatuses = ref<LiveMeasurementPoint[]>([...pageProps.value.operation_mode_statuses]);
  const omConfigurations = ref<LiveMeasurementPoint[]>([...pageProps.value.operation_mode_configurations]);
  const omGroupLabels = pageProps.value.operation_mode_group_labels;

  // Filters
  const selectedSegmentId = ref<number | null>(null);

  function interfaceStatusesForInterface(mp: LiveMeasurementPoint): LiveMeasurementPoint[] {
    if (!mp.interface_communication_type || !mp.interface_io_number)
      return [];

    return interfaceStatuses.value.filter((s) =>
      s.plc_id === mp.plc_id &&
      s.modbus_device_id === mp.modbus_device_id &&
      s.interface_communication_type === mp.interface_communication_type &&
      s.interface_io_number === mp.interface_io_number
    );
  }

  // ── OM detection ────────────────────────────────

  function interfaceKey(mp: LiveMeasurementPoint) {
    if (!mp.interface_communication_type || !mp.interface_io_number)
      return null;

    return `${mp.plc_id}:${mp.modbus_device_id}:${mp.interface_communication_type}:${mp.interface_io_number}`;
  }

  const omInterfaceIndex = computed(() => {
    const index = new Set<string>();
    for (const s of omStatuses.value) {
      const key = interfaceKey(s);
      if (key)
        index.add(key);
    }
    return index;
  });

  function hasOperationMode(mp: LiveMeasurementPoint) {
    const key = interfaceKey(mp);

    if (!key)
      return false;

    return omInterfaceIndex.value.has(key);
  }

  function omStatusesForInterface(mp: LiveMeasurementPoint): LiveMeasurementPoint[] {
    if (!mp.interface_communication_type || !mp.interface_io_number)
      return [];

    return omStatuses.value.filter((s) =>
      s.plc_id === mp.plc_id &&
      s.modbus_device_id === mp.modbus_device_id &&
      s.interface_communication_type === mp.interface_communication_type &&
      s.interface_io_number === mp.interface_io_number
    );
  }

  const mappingsByInterface = computed(() => {
    const map = new Map<string, RegisterMapping[]>();

    const allMps = [...interfaceStatuses.value, ...omStatuses.value, ...omConfigurations.value];
    for (const mp of allMps) {
      const key = interfaceKey(mp);
      if (!key)
        continue;

      if (!map.has(key))
        map.set(key, []);

      map.get(key)!.push({
        register_template: mp.register_template,
        measurement_point: mp,
        position: mp.register_template.position,
      });
    }

    for (const mappings of map.values()) {
      mappings.sort((a, b) => a.position - b.position);
    }

    return map;
  });

  function mappingsForInterface(mp: LiveMeasurementPoint): RegisterMapping[] {
    const key = interfaceKey(mp);
    if (!key)
      return [];

    return mappingsByInterface.value.get(key) ?? [];
  }

  // ── Filtering ───────────────────────────────────

  const filteredMeasurementPoints = computed(() => {
    if (selectedSegmentId.value === null)
      return measurementPoints.value;

    return measurementPoints.value.filter(
      (mp) => mp.segment_id === selectedSegmentId.value
    );
  });

  function toggleSegment(key: string) {
    openSegments[key] = !openSegments[key];
  }

  // ── Segment → Sensors / Control grouping ────────

  function buildControlGroups(controlMps: LiveMeasurementPoint[]): ControlGroupView[] {
    const map = new Map<string, {
      mps: LiveMeasurementPoint[];
      icon: string | null;
      position: number;
    }>();

    for (const mp of controlMps) {
      const cg = mp.measurement_subtype?.control_group;
      const key = cg?.name ?? 'Other';

      if (!map.has(key)) {
        map.set(key, {
          mps: [],
          icon: cg?.icon_key ? (iconMap[cg.icon_key] ?? null) : null,
          position: cg?.position ?? Infinity,
        });
      }
      map.get(key)!.mps.push(mp);
    }

    return Array.from(map.entries())
      .map(([key, { mps, icon, position }]) => ({
        key,
        label: key,
        icon,
        position,
        measurementPoints: mps,
      }))
      .sort((a, b) => a.position - b.position);
  }

  const segmentGroups = computed<SegmentGroup[]>(() => {
    const mps = filteredMeasurementPoints.value;
    const map = new Map<string, LiveMeasurementPoint[]>();

    for (const mp of mps) {
      const key = mp.segment_id ? String(mp.segment_id) : 'unassigned';
      if (!map.has(key))
        map.set(key, []);
      map.get(key)!.push(mp);
    }

    return Array.from(map.entries())
      .map(([key, groupMps]) => {
        const segment = segments.value.find((s) => String(s.id) === key);
        const sensorMps = groupMps.filter((mp) => !hasOperationMode(mp));
        const controlMps = groupMps.filter((mp) => hasOperationMode(mp));

        return {
          key,
          label: segment?.name ?? 'Unassigned',
          allMps: groupMps,
          sensorMps,
          controlGroups: buildControlGroups(controlMps),
          controlMpCount: controlMps.length,
        };
      })
      .sort((a, b) => {
        const segA = segments.value.find((s) => String(s.id) === a.key);
        const segB = segments.value.find((s) => String(s.id) === b.key);
        const posA = segA?.position ?? Infinity;
        const posB = segB?.position ?? Infinity;
        return posA - posB;
      });
  });

  // ── Polling ─────────────────────────────────────

  async function fetchPollData() {
    const { success, data } = await execute<PollResponse>(
      () => axios.get(routePath('live_poll'))
    );

    if (success) {
      for (const update of data.measurement_points) {
        const mp = measurementPoints.value.find((m) => m.id === update.id);
        if (mp) {
          mp.last_value = update.last_value;
          mp.last_value_at = update.last_value_at;
        }
      }

      for (const update of data.interface_statuses) {
        const mp = interfaceStatuses.value.find((m) => m.id === update.id);
        if (mp) {
          mp.last_value = update.last_value;
          mp.last_value_at = update.last_value_at;
        }
      }

      for (const update of data.operation_mode_statuses) {
        const mp = omStatuses.value.find((m) => m.id === update.id);
        if (mp) {
          mp.last_value = update.last_value;
          mp.last_value_at = update.last_value_at;
        }
      }
    }
  }

  const polling = useLivePolling(
    fetchPollData,
    { intervalMs: 5000, immediate: false }
  );

  polling.start();

  // ── Delayed poll ────────────────────────────────

  let delayedPollTimer: ReturnType<typeof setTimeout> | null = null;

  function scheduleDelayedPoll(delayMs = 4000) {
    if (delayedPollTimer)
      clearTimeout(delayedPollTimer);

    delayedPollTimer = setTimeout(() => {
      fetchPollData();
      delayedPollTimer = null;
    }, delayMs);
  }

  // ── Apply write results to local state ──────────

  function applyWriteResult(mp: MeasurementPoint) {
    const existing = measurementPoints.value.find((m) => m.id === mp.id);
    if (existing) {
      existing.last_value = mp.last_value;
      existing.last_value_at = mp.last_value_at;
    }

    const interfaceExisting = interfaceStatuses.value.find((m) => m.id === mp.id);
    if (interfaceExisting) {
      interfaceExisting.last_value = mp.last_value;
      interfaceExisting.last_value_at = mp.last_value_at;
    }

    const omExisting = omStatuses.value.find((m) => m.id === mp.id);
    if (omExisting) {
      omExisting.last_value = mp.last_value;
      omExisting.last_value_at = mp.last_value_at;
    }

    const configExisting = omConfigurations.value.find((m) => m.id === mp.id);
    if (configExisting) {
      configExisting.last_value = mp.last_value;
      configExisting.last_value_at = mp.last_value_at;
    }
  }

  // ── Apply card updates to local state ──

  function handleUpdated(measurementPoints: MeasurementPoint[]) {
    for (const mp of measurementPoints) {
      applyWriteResult(mp);
    }

    scheduleDelayedPoll();
  }

  // ── Analytics Modal ─────────────────────────────

  const analyticsModalVisible = ref(false);
  const analyticsModalMeasurementPoints = ref<LiveMeasurementPoint[]>([]);

  function handleMpClick(mp: LiveMeasurementPoint) {
    analyticsModalMeasurementPoints.value = [mp];
    analyticsModalVisible.value = true;
  }

  function handleSensorGroupClick(segment: SegmentGroup) {
    analyticsModalMeasurementPoints.value = segment.sensorMps;
    analyticsModalVisible.value = true;
  }

  watch(segmentGroups, (groups) => {
    for (const g of groups) {
      if (!(g.key in openSegments)) {
        openSegments[g.key] = true;
      }
    }
  }, { immediate: true });
</script>

<style scoped>
  .collapse {
    visibility: visible;
  }

  .control-group-icon {
    width: 20px;
    height: 20px;
    object-fit: contain;
  }
</style>
