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
              <MeasurementPointCard
                :measurement-point="mp"
                @click="handleMpClick" />
            </div>
          </div>
        </CCardBody>
      </CCard>
    </template>

    <!-- Analytics Modal -->
    <MeasurementPointAnalyticsModal
      :visible="modalVisible"
      :measurement-points="modalMeasurementPoints"
      @close="modalVisible = false" />
  </CContainer>
</template>

<script lang="ts" setup>
  import { ref, computed } from 'vue';
  import axios from 'axios';
  import useAuth from '@/composables/useAuth';
  import { useApiCall } from '@/composables/useApi';
  import { useLivePolling } from '@/composables/useLivePolling';
  import SegmentFilter from '@/components/SegmentFilter.vue';
  import GroupByToggle, { type GroupBy } from '@/components/GroupByToggle.vue';
  import MeasurementPointAnalyticsModal from '@/components/MeasurementPointAnalyticsModal.vue';
  import RelativeTime from '@/components/RelativeTime.vue';
  import MeasurementPointCard from './components/MeasurementPointCard.vue';
  import { ROUTES } from '@/types/permissions';
  import type { MeasurementPoint, MeasurementSubtype } from '@/types/measurementPoint';
  import type { LiveMeasurementPoint } from '@/types/analytics';

  type MeasurementPointGroup = {
    key: string;
    label: string;
    measurementPoints: LiveMeasurementPoint[];
  };

  type PollResponse = {
    measurement_points: {
      id: MeasurementPoint['id'];
      last_value: number | string | null;
      last_value_at: string | null;
      alarm_state: MeasurementPoint['alarm_state'];
    }[];
  };

  const { currentSite, pageProps } = useAuth<{
    measurement_points: LiveMeasurementPoint[];
    measurement_subtypes: MeasurementSubtype[];
  }>();
  const segments = currentSite.value?.segments || [];

  const { execute } = useApiCall();

  // Reactive copy of measurement points for live updates
  const measurementPoints = ref<LiveMeasurementPoint[]>([...pageProps.value.measurement_points]);

  // Filters
  const selectedSegmentId = ref<number | null>(null);
  const groupBy = ref<GroupBy>('measurement_subtype');

  // Modal state
  const modalVisible = ref(false);
  const modalMeasurementPoints = ref<LiveMeasurementPoint[]>([]);

  // Filtered measurement points
  const filteredMeasurementPoints = computed(() => {
    if (selectedSegmentId.value === null)
      return measurementPoints.value;

    return measurementPoints.value.filter(
      (mp) => mp.segment_id === selectedSegmentId.value
    );
  });

  // Grouped measurement points
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

  // Polling
  async function fetchPollData() {
    const { success, data } = await execute<PollResponse>(
      () => axios.get(ROUTES.live_poll.path)
    );

    if (success) {
      const updates = data.measurement_points;
      for (const update of updates) {
        const mp = measurementPoints.value.find((m) => m.id === update.id);
        if (mp) {
          mp.last_value = update.last_value;
          mp.last_value_at = update.last_value_at;
          mp.alarm_state = update.alarm_state;
        }
      }
    }
  }

  const polling = useLivePolling(
    fetchPollData,
    {
      intervalMs: 30000,
      immediate: false
    }
  );

  polling.start();

  // Click handlers
  function handleMpClick(mp: LiveMeasurementPoint) {
    modalMeasurementPoints.value = [mp];
    modalVisible.value = true;
  }

  function handleGroupClick(group: MeasurementPointGroup) {
    modalMeasurementPoints.value = group.measurementPoints;
    modalVisible.value = true;
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
