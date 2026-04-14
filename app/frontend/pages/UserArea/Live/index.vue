<template>
  <CContainer fluid class="px-4 py-2">
    <!-- Header -->
    <div class="d-flex align-items-center justify-content-between mb-2">
      <h2>Live Data</h2>
      <div class="d-flex align-items-center gap-2">
        <span v-if="polling.lastPollAt.value" class="small text-body-secondary">
          Updated <RelativeTime :datetime="polling.lastPollAt.value.toISOString()" />
        </span>
      </div>
    </div>

    <div class="row g-3 align-items-end mb-4">
      <div class="col-auto">
        <SegmentFilter
          v-model="selectedSegmentId"
          :segments="segments" />
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
                class="col-sm-6 col-md-4 col-lg-2">
                <MeasurementPointCard
                  :measurement-point="mp"
                  @click="handleMpClick" />
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
                  class="col-sm-6 col-md-4 col-lg-2">
                  <OutputControlCard
                    :ref="(el: any) => setOutputCardRef(mp.id, el)"
                    :measurement-point="mp"
                    :om-statuses="omStatusesForInterface(mp)"
                    @analytics="handleMpClick"
                    @configure="handleConfigureClick"
                    @write="handleQuickWrite"
                    @bulk-write="handleBulkWrite" />
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

    <!-- Operation Mode Configure Modal -->
    <CModal
      :visible="omModalVisible"
      size="xl"
      backdrop="static"
      @close="handleOmModalClose">
      <CModalHeader>
        <CModalTitle v-if="omModalMp">
          Configure — {{ omModalMp.name }}
        </CModalTitle>
      </CModalHeader>
      <CModalBody>
        <div v-if="omModalLoading" class="text-center py-5">
          <CSpinner color="primary" />
          <p class="text-body-secondary mt-2">Loading configuration...</p>
        </div>
        <OperationModePanel
          v-else-if="omModalData"
          :mappings="omModalData.register_mappings"
          :config-values="omConfigValues"
          :group-labels="omModalData.group_labels"
          :available-sources="omModalData.available_sources"
          @value-change="handleOmValueChange"
          @write="handleOmImmediateWrite" />
      </CModalBody>
      <CModalFooter v-if="omModalData && omHasChanges">
        <CButton color="secondary" variant="ghost" @click="handleOmModalClose">
          Cancel
        </CButton>
        <CButton color="primary" :disabled="omSaving" @click="handleOmSave">
          {{ omSaving ? 'Saving...' : 'Save & Apply' }}
        </CButton>
      </CModalFooter>
    </CModal>
  </CContainer>
</template>

<script lang="ts" setup>
  import { ref, computed, reactive, watch } from 'vue';
  import axios from 'axios';
  import useAuth from '@/composables/useAuth';
  import { useApiCall } from '@/composables/useApi';
  import { useLivePolling } from '@/composables/useLivePolling';
  import type { ConfigValues } from '@/composables/useConfigurationValues';
  import SegmentFilter from '@/components/SegmentFilter.vue';
  import MeasurementPointAnalyticsModal from '@/components/MeasurementPointAnalyticsModal.vue';
  import RelativeTime from '@/components/RelativeTime.vue';
  import OperationModePanel from '@/components/OperationMode/OperationModePanel.vue';
  import MeasurementPointCard from './components/MeasurementPointCard.vue';
  import OutputControlCard from './components/OutputControlCard.vue';
  import { ROUTES } from '@/types/permissions';
  import type { MeasurementPoint, MeasurementSubtype } from '@/types/measurementPoint';
  import type { MeasurementPointConfigResponse } from '@/types/plc';
  import type { LiveMeasurementPoint, OperationModeConfigResponse } from '@/types/analytics';
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
      alarm_state: MeasurementPoint['alarm_state'];
    }[];
    operation_mode_statuses: {
      id: MeasurementPoint['id'];
      last_value: MeasurementPoint['last_value'];
      last_value_at: MeasurementPoint['last_value_at'];
      effective_unit: MeasurementPoint['effective_unit'];
      alarm_state: MeasurementPoint['alarm_state'];
    }[];
  };

  const { currentSite, pageProps } = useAuth<{
    measurement_points: LiveMeasurementPoint[];
    operation_mode_statuses: LiveMeasurementPoint[];
    measurement_subtypes: MeasurementSubtype[];
  }>();
  const segments = currentSite.value?.segments || [];

  const { execute } = useApiCall();

  const openSegments = reactive<Record<string, boolean>>({});
  const outputCardRefs = new Map<number, InstanceType<typeof OutputControlCard>>();

  function setOutputCardRef(mpId: number, el: InstanceType<typeof OutputControlCard> | null) {
    if (el)
      outputCardRefs.set(mpId, el);
    else
      outputCardRefs.delete(mpId);
  }

  // ── Reactive data ───────────────────────────────

  const measurementPoints = ref<LiveMeasurementPoint[]>([...pageProps.value.measurement_points]);
  const omStatuses = ref<LiveMeasurementPoint[]>([...pageProps.value.operation_mode_statuses]);

  // Filters
  const selectedSegmentId = ref<number | null>(null);

  // ── OM detection ────────────────────────────────

  const omInterfaceIndex = computed(() => {
    const index = new Set<string>();
    for (const s of omStatuses.value) {
      if (s.interface_communication_type && s.interface_io_number)
        index.add(`${s.interface_communication_type}:${s.interface_io_number}`);
    }
    return index;
  });

  function hasOperationMode(mp: LiveMeasurementPoint): boolean {
    if (!mp.interface_communication_type || !mp.interface_io_number)
      return false;

    return omInterfaceIndex.value.has(
      `${mp.interface_communication_type}:${mp.interface_io_number}`
    );
  }

  function omStatusesForInterface(mp: LiveMeasurementPoint): LiveMeasurementPoint[] {
    if (!mp.interface_communication_type || !mp.interface_io_number)
      return [];

    return omStatuses.value.filter((s) =>
      s.interface_communication_type === mp.interface_communication_type &&
      s.interface_io_number === mp.interface_io_number
    );
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
        const segment = segments.find((s) => String(s.id) === key);
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
      // .sort((a, b) => {
      //   const segA = segments.find((s) => String(s.id) === a.key);
      //   const segB = segments.find((s) => String(s.id) === b.key);
      //   const posA = segA?.position ?? Infinity;
      //   const posB = segB?.position ?? Infinity;
      //   return posA - posB;
      // });
  });

  // ── Polling ─────────────────────────────────────

  async function fetchPollData() {
    const { success, data } = await execute<PollResponse>(
      () => axios.get(ROUTES.live_poll.path)
    );

    if (success) {
      for (const update of data.measurement_points) {
        const mp = measurementPoints.value.find((m) => m.id === update.id);
        if (mp) {
          mp.last_value = update.last_value;
          mp.last_value_at = update.last_value_at;
          mp.alarm_state = update.alarm_state;
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
    { intervalMs: 30000, immediate: false }
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
      if (mp.alarm_state)
        existing.alarm_state = mp.alarm_state;
    }

    const omExisting = omStatuses.value.find((m) => m.id === mp.id);
    if (omExisting) {
      omExisting.last_value = mp.last_value;
      omExisting.last_value_at = mp.last_value_at;
    }
  }

  function applyWriteResultToCard(anchorMpId: number, updates: MeasurementPoint[]) {
    const card = outputCardRefs.get(anchorMpId);
    if (card) {
      card.updateMappings(updates);
    }
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

  // ── Quick Write ─────────────────────────────────

  async function handleQuickWrite(
    measurementPointId: MeasurementPoint['id'],
    value: NonNullable<MeasurementPoint['last_value']>
  ) {
    const writePath = ROUTES.measurement_points_write.path.replace(':id', String(measurementPointId));
    const { success, data } = await execute<MeasurementPoint>(
      () => axios.post(writePath, { value })
    );

    if (success) {
      applyWriteResult(data);
      for (const [cardMpId, card] of outputCardRefs) {
        card.updateMappings([data]);
      }
      scheduleDelayedPoll();
    }
  }

  // ── Bulk Write ──────────────────────────────────

  async function handleBulkWrite(
    anchorMpId: MeasurementPoint['id'],
    updates: { measurement_point_id: MeasurementPoint['id']; value: NonNullable<MeasurementPoint['last_value']> }[]
  ) {
    if (updates.length === 0)
      return;

    const updatePath = ROUTES.measurement_points_update.path
      .replace(':id', String(anchorMpId));

    const configurationUpdates = updates.map((u) => ({
      measurement_point_id: u.measurement_point_id,
      value: u.value,
    }));

    const { success, data } = await execute<MeasurementPointConfigResponse>(
      () => axios.patch(updatePath, { configuration_updates: configurationUpdates })
    );

    if (success) {
      applyWriteResult(data.measurement_point);

      for (const sibling of data.sibling_measurement_points) {
        applyWriteResult(sibling);
      }

      applyWriteResultToCard(anchorMpId, data.sibling_measurement_points);
      scheduleDelayedPoll();
    }
  }

  // ── Operation Mode Configure Modal ──────────────

  const omModalVisible = ref(false);
  const omModalLoading = ref(false);
  const omSaving = ref(false);
  const omModalMp = ref<LiveMeasurementPoint | null>(null);
  const omModalData = ref<OperationModeConfigResponse | null>(null);
  const omConfigValues = reactive<ConfigValues>({});
  const omEditedIds = ref(new Set<MeasurementPoint['id']>());

  const omHasChanges = computed(() => omEditedIds.value.size > 0);

  async function handleConfigureClick(mp: LiveMeasurementPoint) {
    omModalMp.value = mp;
    omModalVisible.value = true;
    omModalLoading.value = true;
    omEditedIds.value = new Set();

    const configPath = ROUTES.measurement_points_operation_mode_config.path
      .replace(':id', String(mp.id));

    const { success, data } = await execute<OperationModeConfigResponse>(
      () => axios.get(configPath)
    );

    if (!success) {
      omModalLoading.value = false;
      return;
    }

    omModalData.value = data;

    for (const rm of data.register_mappings) {
      omConfigValues[rm.measurement_point.id] = rm.measurement_point.last_value;
    }

    omModalLoading.value = false;
  }

  function handleOmValueChange(
    measurementPointId: MeasurementPoint['id'],
    value: MeasurementPoint['last_value']
  ) {
    omConfigValues[measurementPointId] = value;
    omEditedIds.value.add(measurementPointId);
  }

  async function handleOmImmediateWrite(
    measurementPointId: MeasurementPoint['id'],
    value: NonNullable<MeasurementPoint['last_value']>
  ) {
    const writePath = ROUTES.measurement_points_write.path.replace(':id', String(measurementPointId));
    const { success, data } = await execute<MeasurementPoint>(
      () => axios.post(writePath, { value })
    );

    if (success) {
      applyWriteResult(data);
      omConfigValues[data.id] = data.last_value;
      scheduleDelayedPoll();
    }
  }

  async function handleOmSave() {
    if (omEditedIds.value.size === 0 || !omModalMp.value)
      return;

    omSaving.value = true;

    const anchorMpId = omModalMp.value.id;
    const updatePath = ROUTES.measurement_points_update.path.replace(':id', String(anchorMpId));
    const configurationUpdates = Array.from(omEditedIds.value).map(mpId => ({
      measurement_point_id: mpId,
      value: omConfigValues[mpId],
    }));

    const { success, data } = await execute<MeasurementPointConfigResponse>(
      () => axios.patch(updatePath, { configuration_updates: configurationUpdates })
    );

    omSaving.value = false;

    if (success) {
      applyWriteResult(data.measurement_point);
      for (const sibling of data.sibling_measurement_points) {
        applyWriteResult(sibling);
      }

      applyWriteResultToCard(anchorMpId, data.sibling_measurement_points);

      omEditedIds.value = new Set();
      omModalVisible.value = false;
      scheduleDelayedPoll();
    }
  }

  function handleOmModalClose() {
    omModalVisible.value = false;
    omModalData.value = null;
    omModalMp.value = null;
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
