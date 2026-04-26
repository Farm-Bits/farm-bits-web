<template>
  <div>
    <CTabs
      v-if="om.tabs.value.length > 1"
      v-model:active-item-key="activeTab"
      variant="tabs">
      <CTabList variant="tabs">
        <CTab
          v-for="tab in om.tabs.value"
          :key="tab.id"
          :item-key="tab.id"
          class="tab-item">
          {{ tab.label }}
        </CTab>
      </CTabList>
      <CTabContent>
        <CTabPanel
          v-for="tab in om.tabs.value"
          :key="tab.id"
          :item-key="tab.id">
          <template
            v-for="section in sectionsFor(tab.id)"
            :key="section.key">
            <div
              v-if="section.heading"
              class="mb-3">
              <h6 class="text-body-secondary small fw-semibold text-uppercase mb-2">
                {{ section.heading }}
              </h6>
            </div>

            <component
              :is="section.component"
              :mappings="mappings"
              :config-values="configValues"
              :available-sources="availableSources"
              v-bind="section.extraProps"
              @value-change="handleValueChange"
              @write="handleImmediateWrite" />
          </template>
        </CTabPanel>
      </CTabContent>
    </CTabs>

    <!-- Single tab — no tab chrome needed -->
    <template v-else>
      <template
        v-for="section in activeSections"
        :key="section.key">
        <div
          v-if="section.heading"
          class="mb-3">
          <h6 class="text-body-secondary small fw-semibold text-uppercase mb-2">
            {{ section.heading }}
          </h6>
        </div>

        <component
          :is="section.component"
          :mappings="mappings"
          :config-values="configValues"
          :available-sources="availableSources"
          v-bind="section.extraProps"
          @value-change="handleValueChange"
          @write="handleImmediateWrite" />
      </template>
    </template>
  </div>
</template>

<script lang="ts" setup>
  import { ref, computed, type Component, type Raw, markRaw } from 'vue';
  import DutyCycleConfig from './features/DutyCycleConfig.vue';
  import SafetyConfig from './features/SafetyConfig.vue';
  import TimeWindowConfig from './features/TimeWindowConfig.vue';
  import ScheduleSlot from './features/ScheduleSlot.vue';
  import SensorTriggerConfig from './features/SensorTriggerConfig.vue';
  import { useOperationMode } from '@/composables/useOperationMode';
  import type { ConfigValues } from '@/composables/useConfigurationValues';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { RegisterMapping, SourceIoInfo } from '@/types/plc';
  import type { OmGroupNameOrSlot } from '@/types/operationMode';
  import { OM_GROUPS } from '@/types/operationMode';

  const { mappings, configValues, groupLabels, availableSources } = defineProps<{
    mappings: RegisterMapping[];
    configValues: ConfigValues;
    groupLabels: Record<OmGroupNameOrSlot | string, string>;
    availableSources: SourceIoInfo[];
  }>();

  const emit = defineEmits<{
    (e: 'value-change', measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']): void;
    (e: 'write', measurementPointId: MeasurementPoint['id'], value: NonNullable<MeasurementPoint['last_value']>): void;
  }>();

  const mappingsRef = computed(() => mappings);
  const labelsRef = computed(() => groupLabels);
  const om = useOperationMode(mappingsRef, labelsRef);

  const activeTab = ref(om.tabs.value[0]?.id ?? 'control');

  // ── Tab → Sections Registry ─────────────────────

  type SectionDef = {
    key: string;
    component: Raw<Component>;
    visible: () => boolean;
    heading?: () => string | null;
    extraProps?: () => Record<string, unknown>;
  };

  const TAB_SECTIONS: Record<string, SectionDef[]> = {
    dutycycle: [
      {
        key: 'dutycycle',
        component: markRaw(DutyCycleConfig),
        visible: () => om.hasDutyCycle.value
      }
    ],
    schedules: [
      // One section per schedule slot — dynamic based on discovered groups
      ...buildScheduleSections()
    ],
    sensors: [
      {
        key: 'sensor-trigger',
        component: markRaw(SensorTriggerConfig),
        visible: () => om.hasSensor.value || om.hasSensorConditions.value,
        extraProps: () => ({
          conditionGroupNames: om.sensorConditionGroups.value,
          labelFor: om.labelFor,
          slotNumber: om.slotNumber
        })
      }
    ],
    settings: [
      {
        key: 'window',
        component: markRaw(TimeWindowConfig),
        visible: () => om.hasWindow.value,
        heading: () => om.labelFor(OM_GROUPS.window)
      },
      {
        key: 'safety',
        component: markRaw(SafetyConfig),
        visible: () => om.hasSafety.value,
        heading: () => om.labelFor(OM_GROUPS.safety)
      }
    ]
  };

  /**
   * Build schedule sections dynamically from discovered schedule groups.
   * Each slot is a separate section so they render independently.
   */
  function buildScheduleSections(): SectionDef[] {
    // This runs once at setup — schedule groups are stable for a given Modbus Firmware Version.
    // If no schedules exist, the tab won't show (useOperationMode handles that).
    return om.scheduleGroups.value.map(groupName => ({
      key: `schedule-${groupName}`,
      component: markRaw(ScheduleSlot),
      visible: () => true,
      extraProps: () => ({
        groupName,
        slotNumber: om.slotNumber(groupName),
        label: om.labelFor(groupName),
      }),
    }));
  }

  // ── Active sections for current tab ─────────────

  type ResolvedSection = {
    key: string;
    component: Raw<Component>;
    heading: string | null;
    extraProps: Record<string, unknown>;
  };

  const activeSections = computed<ResolvedSection[]>(() => {
    const sections = TAB_SECTIONS[activeTab.value];
    if (!sections)
      return [];

    return sections
      .filter((s) => s.visible())
      .map((s) => ({
        key: s.key,
        component: s.component,
        heading: s.heading?.() ?? null,
        extraProps: s.extraProps?.() ?? {},
      }));
  });

  function sectionsFor(tabId: string): ResolvedSection[] {
    const sections = TAB_SECTIONS[tabId];
    if (!sections)
      return [];

    return sections
      .filter((s) => s.visible())
      .map((s) => ({
        key: s.key,
        component: s.component,
        heading: s.heading?.() ?? null,
        extraProps: s.extraProps?.() ?? {},
      }));
  }

  // ── Event handlers ──────────────────────────────

  function handleValueChange(measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']) {
    emit('value-change', measurementPointId, value);
  }

  function handleImmediateWrite(measurementPointId: MeasurementPoint['id'], value: NonNullable<MeasurementPoint['last_value']>) {
    emit('write', measurementPointId, value);
  }
</script>
