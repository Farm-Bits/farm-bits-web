<template>
  <OutputControlCard
    v-if="isControl"
    :measurement-point="measurementPoint"
    :register-mappings="registerMappings"
    :interface-statuses="interfaceStatuses"
    :om-statuses="omStatuses"
    :om-group-labels="omGroupLabels"
    @analytics="(mp) => emit('analytics', mp)"
    @updated="(mps) => emit('updated', mps)" />

  <MeasurementPointCard
    v-else
    :measurement-point="measurementPoint"
    :interface-statuses="interfaceStatuses"
    :register-mappings="registerMappings"
    @click="(mp) => emit('analytics', mp)" />
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import MeasurementPointCard from './MeasurementPointCard.vue';
  import OutputControlCard from './OutputControlCard.vue';
  import type { LiveMeasurementPoint } from '@/types/analytics';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { RegisterMapping } from '@/types/plc';
  import type { OmGroupNameOrSlot } from '@/types/operationMode';

  // Single entry point for displaying a live measurement anywhere. Renders the
  // read-only sensor card by default; renders the interactive control card only
  // when controls are enabled AND the measurement's interface carries
  // operation-mode registers (omStatuses present). The control card brings its
  // own behavior (configure/write/command/e-stop) and emits `updated` with the
  // changed measurement points; the host syncs its data and owns analytics.
  const {
    measurementPoint,
    interfaceStatuses = [],
    omStatuses = [],
    registerMappings = [],
    omGroupLabels = {},
    enableControl = false
  } = defineProps<{
    measurementPoint: LiveMeasurementPoint;
    interfaceStatuses?: LiveMeasurementPoint[];
    omStatuses?: LiveMeasurementPoint[];
    registerMappings?: RegisterMapping[];
    omGroupLabels?: Record<OmGroupNameOrSlot | string, string>;
    enableControl?: boolean;
  }>();

  const emit = defineEmits<{
    (e: 'analytics', mp: LiveMeasurementPoint): void;
    (e: 'updated', measurementPoints: MeasurementPoint[]): void;
  }>();

  const isControl = computed(() => enableControl && omStatuses.length > 0);
</script>
