<template>
  <CContainer fluid class="px-4 py-4">
    <!-- Header -->
    <div class="d-flex align-items-center justify-content-between mb-4">
      <div>
        <h2 class="mb-1">Live Data</h2>
        <p class="text-body-secondary mb-0">
          Real-time overview of active measurement points for {{ currentSite?.name }}
        </p>
      </div>
      <div class="d-flex align-items-center gap-2">
        <span v-if="polling.lastPollAt.value" class="small text-body-secondary">
          Updated <RelativeTime :datetime="polling.lastPollAt.value.toISOString()" />
        </span>
      </div>
    </div>

    <!-- Filter bar -->
    <CCard class="mb-4 shadow-sm">
      <CCardBody class="py-3">
        <div class="row g-3 align-items-end">
          <div class="col-auto">
            <SegmentFilter
              v-model="selectedSegmentId"
              :segments="segments" />
          </div>
          <div class="col-auto">
            <GroupByToggle v-model="groupBy" />
          </div>
        </div>
      </CCardBody>
    </CCard>

    <!-- Empty state -->
    <div v-if="filteredMeasurementPoints.length === 0" class="text-center py-5">
      <CIcon name="cil-speedometer" size="3xl" class="text-body-secondary mb-3" />
      <h5 class="text-body-secondary">No active measurement points</h5>
      <p class="text-body-secondary">
        There are no active measurement points collecting data for this site.
      </p>
    </div>

    <!-- Grouped measurement points -->
    <template v-else>
      <CCard
        v-for="group in groups"
        :key="group.key"
        class="mb-4 shadow-sm">
        <CCardHeader
          class="group-header"
          role="button"
          @click="handleGroupClick(group)">
          <div class="d-flex align-items-center justify-content-between">
            <h6 class="mb-0">
              {{ group.label }}
              <CBadge color="light" class="ms-2 text-body-secondary">
                {{ group.measurementPoints.length }}
              </CBadge>
            </h6>
            <small class="text-body-secondary">Click to view analytics</small>
          </div>
        </CCardHeader>
        <CCardBody>
          <div class="row g-3">
            <div
              v-for="mp in group.measurementPoints"
              :key="mp.id"
              class="col-sm-6 col-md-4 col-lg-3">
              <OutputControlCard
                v-if="hasOperationMode(mp)"
                :ref="(el: any) => setOutputCardRef(mp.id, el)"
                :measurement-point="mp"
                :om-statuses="omStatusesForInterface(mp)"
                @analytics="handleMpClick"
                @configure="handleConfigureClick"
                @write="handleQuickWrite"
                @bulk-write="handleBulkWrite" />

              <MeasurementPointCard
                v-else
                :measurement-point="mp"
                @click="handleMpClick" />
            </div>
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
  import { ref, computed, reactive } from 'vue';
  import axios from 'axios';
  import useAuth from '@/composables/useAuth';
  import { useApiCall } from '@/composables/useApi';
  import { useLivePolling } from '@/composables/useLivePolling';
  import type { ConfigValues } from '@/composables/useConfigurationValues';
  import SegmentFilter from '@/components/SegmentFilter.vue';
  import GroupByToggle, { type GroupBy } from '@/components/GroupByToggle.vue';
  import MeasurementPointAnalyticsModal from '@/components/MeasurementPointAnalyticsModal.vue';
  import RelativeTime from '@/components/RelativeTime.vue';
  import OperationModePanel from '@/components/OperationMode/OperationModePanel.vue';
  import MeasurementPointCard from './components/MeasurementPointCard.vue';
  import OutputControlCard from './components/OutputControlCard.vue';
  import { ROUTES } from '@/types/permissions';
  import type { MeasurementPoint, MeasurementSubtype } from '@/types/measurementPoint';
  import type { MeasurementPointConfigResponse } from '@/types/plc';
  import type { LiveMeasurementPoint, OperationModeConfigResponse } from '@/types/analytics';

  type MeasurementPointGroup = {
    key: string;
    label: string;
    measurementPoints: LiveMeasurementPoint[];
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

  const outputCardRefs = new Map<number, InstanceType<typeof OutputControlCard>>();

  function setOutputCardRef(mpId: number, el: InstanceType<typeof OutputControlCard> | null) {
    if (el) {
      outputCardRefs.set(mpId, el);
    } else {
      outputCardRefs.delete(mpId);
    }
  }

  // ── Reactive data ───────────────────────────────

  const measurementPoints = ref<LiveMeasurementPoint[]>([...pageProps.value.measurement_points]);
  const omStatuses = ref<LiveMeasurementPoint[]>([...pageProps.value.operation_mode_statuses]);

  // Filters
  const selectedSegmentId = ref<number | null>(null);
  const groupBy = ref<GroupBy>('measurement_subtype');

  // ── OM detection ────────────────────────────────
  //
  // A measurement point has operation mode if there are OM status registers
  // for its interface. Detected by matching interface_communication_type +
  // interface_io_number. Works for any interface type (DO, AO, etc.).

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

  // ── Filtering & Grouping ────────────────────────

  const filteredMeasurementPoints = computed(() => {
    if (selectedSegmentId.value === null)
      return measurementPoints.value;

    return measurementPoints.value.filter(
      (mp) => mp.segment_id === selectedSegmentId.value
    );
  });

  const groups = computed<MeasurementPointGroup[]>(() => {
    const mps = filteredMeasurementPoints.value;

    if (groupBy.value === 'segment')
      return groupBySegment(mps);

    return groupByMeasurementType(mps);
  });

  function groupBySegment(mps: LiveMeasurementPoint[]) {
    const map = new Map<string, LiveMeasurementPoint[]>();

    for (const mp of mps) {
      const key = mp.segment_id ? String(mp.segment_id) : 'unassigned';
      if (!map.has(key))
        map.set(key, []);

      map.get(key)!.push(mp);
    }

    return Array.from(map.entries()).map(([key, groupMps]) => {
      const segment = segments.find((s) => String(s.id) === key);
      return {
        key,
        label: segment?.name ?? 'Unassigned',
        // position: segment?.position ?? Infinity,
        measurementPoints: groupMps,
      };
    });
    // .sort((a, b) => a.position - b.position);
  }

  function groupByMeasurementType(mps: LiveMeasurementPoint[]): MeasurementPointGroup[] {
    const map = new Map<string, { mps: LiveMeasurementPoint[]; position: number }>();
    for (const mp of mps) {
      const type = mp.measurement_subtype?.measurement_type;
      const typeName = type?.name ?? 'Unknown';
      if (!map.has(typeName))
        map.set(typeName, { mps: [], position: type?.position ?? Infinity });

      map.get(typeName)!.mps.push(mp);
    }
    return Array.from(map.entries())
      .sort(([, a], [, b]) => a.position - b.position)
      .map(([key, { mps: groupMps }]) => ({
        key,
        label: key,
        measurementPoints: groupMps.sort((a, b) => {
          const posA = a.measurement_subtype?.position ?? Infinity;
          const posB = b.measurement_subtype?.position ?? Infinity;
          return posA - posB;
        }),
      }));
  }

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

  // ── Delayed poll (for status registers to catch up after PLC processes a command) ──

  let delayedPollTimer: ReturnType<typeof setTimeout> | null = null;

  function scheduleDelayedPoll(delayMs = 4000) {
    if (delayedPollTimer)
      clearTimeout(delayedPollTimer);

    delayedPollTimer = setTimeout(() => {
      fetchPollData();
      delayedPollTimer = null;
    }, delayMs);
  }

  // ── Apply write results to local state ──

  function applyWriteResult(mp: MeasurementPoint) {
    // Patch main measurement points list
    const existing = measurementPoints.value.find((m) => m.id === mp.id);
    if (existing) {
      existing.last_value = mp.last_value;
      existing.last_value_at = mp.last_value_at;
      if (mp.alarm_state)
        existing.alarm_state = mp.alarm_state;
    }

    // Patch OM statuses list
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

  function handleGroupClick(group: MeasurementPointGroup) {
    analyticsModalMeasurementPoints.value = group.measurementPoints;
    analyticsModalVisible.value = true;
  }

  // ── Quick Write (immediate PLC command) ─────────

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
      // Find which card this MP belongs to and patch its local mappings
      for (const [cardMpId, card] of outputCardRefs) {
        card.updateMappings([data]);
      }
      scheduleDelayedPoll();
    }
  }

  // ── Bulk Write (params + command in sequence) ──

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
      // Apply the anchor MP
      applyWriteResult(data.measurement_point);

      // Apply all sibling updates (includes the config registers that were written)
      for (const sibling of data.sibling_measurement_points) {
        applyWriteResult(sibling);
      }

      // Patch the OutputControlCard's local mappings
      applyWriteResultToCard(anchorMpId, data.sibling_measurement_points);

      scheduleDelayedPoll();
    }
  }

  // ── Operation Mode Configure Modal ──────────────
  //
  // Uses the new operation_mode_config endpoint — lightweight,
  // returns only OM registers for the specific interface.

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
      // Update the OM modal's config values with the write result
      omConfigValues[data.id] = data.last_value;
      scheduleDelayedPoll();
    }
  }

  async function handleOmSave() {
    if (omEditedIds.value.size === 0 || !omModalMp.value)
      return;

    omSaving.value = true;

    // Anchor is the data-category MP that opened the modal
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
      // Apply anchor + all sibling updates to local state
      applyWriteResult(data.measurement_point);
      for (const sibling of data.sibling_measurement_points) {
        applyWriteResult(sibling);
      }

      // Patch the OutputControlCard's local OM mappings
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
</script>

<style scoped>
  .group-header {
    cursor: pointer;
    transition: background-color 0.15s;
  }

  .group-header:hover {
    background-color: #f9fafb;
  }
</style>
