<template>
  <div
    class="border rounded mb-2"
    :class="isEnabled ? 'border-info-subtle' : ''">
    <!-- Header -->
    <div
      v-if="enabledMapping"
      class="d-flex align-items-center gap-2 px-3 py-2"
      role="button"
      @click="isOpen = !isOpen">
      <template v-if="removable">
        <span class="flex-grow-1 fw-medium">
          {{ label }} {{ slotNumber }}
          <template v-if="!isOpen && summaryText">
            <small class="text-body-secondary ms-2">{{ summaryText }}</small>
          </template>
        </span>
        <CButton color="danger" variant="ghost" size="sm" @click.stop="handleRemove">
          Remove
        </CButton>
        <small class="text-body-secondary">{{ isOpen ? '▴' : '▾' }}</small>
      </template>
      <template v-else>
        <CFormLabel class="fw-semibold d-flex align-items-center gap-2">
          {{ enabledMapping.register_template.name }}
          <CTooltip
            v-if="enabledMapping.register_template.description"
            :content="enabledMapping.register_template.description">
            <template #toggler="{ on }">
              <CIcon v-on="on" icon="cilInfo" size="sm" class="text-muted" />
            </template>
          </CTooltip>
        </CFormLabel>
        <CFormSwitch
          :model-value="isEnabled"
          @click.stop
          @update:model-value="handleToggle" />
        <span
          class="flex-grow-1 fw-medium"
          :class="isEnabled ? '' : 'text-body-secondary'">
          {{ label }} {{ slotNumber }}
          <template v-if="!isOpen && isEnabled">
            <small class="text-body-secondary ms-2">{{ summaryText }}</small>
          </template>
        </span>
        <small class="text-body-secondary">{{ isOpen ? '▴' : '▾' }}</small>
      </template>
    </div>

    <!-- Body -->
    <div
      v-if="isOpen"
      class="px-3 pb-3">
      <!-- Start time: sun reference composite -->
      <div class="row g-3 mb-2">
        <div class="col-6" v-if="startRefMapping">
          <CFormLabel class="fw-semibold d-flex align-items-center gap-2">
            {{ startRefMapping.register_template.name }}
            <CTooltip
              v-if="startRefMapping.register_template.description"
              :content="startRefMapping.register_template.description">
              <template #toggler="{ on }">
                <CIcon v-on="on" icon="cilInfo" size="sm" class="text-muted" />
              </template>
            </CTooltip>
          </CFormLabel>
          <RegisterField
            :model-value="configValues[startRefMapping.measurement_point.id]"
            :register-mapping="startRefMapping"
            :is-editing="true"
            @update:model-value="emitChange(startRefMapping.measurement_point.id, $event)" />
        </div>
        <div class="col-6" v-if="startTimeOrOffsetMapping">
          <CFormLabel class="fw-semibold d-flex align-items-center gap-2">
            {{ startTimeOrOffsetMapping.register_template.name }}
            <CTooltip
              v-if="startTimeOrOffsetMapping.register_template.description"
              :content="startTimeOrOffsetMapping.register_template.description">
              <template #toggler="{ on }">
                <CIcon v-on="on" icon="cilInfo" size="sm" class="text-muted" />
              </template>
            </CTooltip>
          </CFormLabel>
          <RegisterField
            :model-value="configValues[startTimeOrOffsetMapping.measurement_point.id]"
            :register-mapping="startTimeOrOffsetMapping"
            :is-editing="true"
            @update:model-value="emitChange(startTimeOrOffsetMapping.measurement_point.id, $event)" />
        </div>
      </div>

      <!-- Remaining fields in defined position, one-time date folded in place. -->
      <template
        v-for="item in remainingItems"
        :key="item.key">
        <div
          v-if="item.kind === 'onetimeDate'"
          class="mb-2">
          <CFormLabel class="fw-semibold">Date</CFormLabel>
          <CFormInput
            type="date"
            :model-value="onetimeDateValue"
            @update:model-value="handleOnetimeDateChange" />
        </div>
        <div
          v-else
          class="mb-2">
          <CFormLabel class="fw-semibold d-flex align-items-center gap-2">
            {{ item.mapping.register_template.name }}
            <CTooltip
              v-if="item.mapping.register_template.description"
              :content="item.mapping.register_template.description">
              <template #toggler="{ on }">
                <CIcon v-on="on" icon="cilInfo" size="sm" class="text-muted" />
              </template>
            </CTooltip>
          </CFormLabel>
          <RegisterField
            :model-value="configValues[item.mapping.measurement_point.id]"
            :register-mapping="item.mapping"
            :is-editing="true"
            @update:model-value="emitChange(item.mapping.measurement_point.id, $event)" />
        </div>
      </template>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed, ref } from 'vue';
  import RegisterField from '@/components/RegisterField.vue';
  import { useGroupRegisters } from '@/composables/useGroupRegisters';
  import type { ConfigValues } from '@/composables/useConfigurationValues';
  import type { RegisterMapping } from '@/types/plc';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import { OM_ROLES } from '@/types/operationMode';

  type ScheduleItem =
    | { kind: 'onetimeDate'; key: string }
    | { kind: 'register'; key: string; mapping: RegisterMapping };

  const { mappings, groupName, slotNumber, label, configValues, removable = false } = defineProps<{
    mappings: RegisterMapping[];
    groupName: string;
    slotNumber: number;
    label: string;
    configValues: ConfigValues;
    removable?: boolean;
  }>();

  const emit = defineEmits<{
    (e: 'value-change', measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']): void;
  }>();

  const mappingsRef = computed(() => mappings);
  const groupNameRef = computed(() => groupName);
  const { getValue, mpForRole, mappingForRole, mappingsExcept } = useGroupRegisters(mappingsRef, groupNameRef);

  // Managed slots open by default; the toggle-style usage stays collapsed.
  const isOpen = ref(removable);

  // ── State ────────────────────────────────────────

  const isEnabled = computed(() => {
    const mpId = mpForRole(OM_ROLES.enabled)?.id;
    if (!mpId)
      return false;

    return String(configValues[mpId]) === '1';
  });

  const enabledMapping = computed(() => mappingForRole(OM_ROLES.enabled));

  // ── Start time: sun reference composite ──────────

  const startRefMapping = computed(() => mappingForRole(OM_ROLES.startRef));

  const isStartFixed = computed(() => {
    const mpId = mpForRole(OM_ROLES.startRef)?.id;
    if (!mpId)
      return true;

    return String(configValues[mpId]) === '0';
  });

  const startTimeOrOffsetMapping = computed(() => {
    if (isStartFixed.value)
      return mappingForRole(OM_ROLES.startTime);

    return mappingForRole(OM_ROLES.startOffset);
  });

  // ── One-time date composite (onetime_day + onetime_month + onetime_year) ──

  const onetimeDayMapping = computed(() => mappingForRole(OM_ROLES.onetimeDay));
  const onetimeMonthMapping = computed(() => mappingForRole(OM_ROLES.onetimeMonth));
  const onetimeYearMapping = computed(() => mappingForRole(OM_ROLES.onetimeYear));

  const hasOnetimeDate = computed(() =>
    !!onetimeDayMapping.value && !!onetimeMonthMapping.value && !!onetimeYearMapping.value
  );

  const onetimeDateValue = computed(() => {
    const d = numericValueFor(onetimeDayMapping.value);
    const m = numericValueFor(onetimeMonthMapping.value);
    const y = numericValueFor(onetimeYearMapping.value);

    // 0 or unset on any part means no date has been chosen (register default).
    if (!d || !m || !y)
      return '';

    return `${y}-${pad(m)}-${pad(d)}`;
  });

  function handleOnetimeDateChange(value: string) {
    if (!value)
      return;

    const [y, m, d] = value.split('-').map(Number);

    const dayMp = onetimeDayMapping.value?.measurement_point;
    const monthMp = onetimeMonthMapping.value?.measurement_point;
    const yearMp = onetimeYearMapping.value?.measurement_point;

    if (dayMp)
      emit('value-change', dayMp.id, d);

    if (monthMp)
      emit('value-change', monthMp.id, m);

    if (yearMp)
      emit('value-change', yearMp.id, y);
  }

  // ── Remaining fields (everything except known layout roles), in position ──

  const layoutRoles = [
    OM_ROLES.enabled,
    OM_ROLES.startRef, OM_ROLES.startTime, OM_ROLES.startOffset,
  ];

  const remainingMappings = computed(() => mappingsExcept(...layoutRoles));

  const visibleRemainingMappings = computed(() =>
    remainingMappings.value.filter(rm => isVisible(rm))
  );

  const remainingItems = computed<ScheduleItem[]>(() => {
    const items: ScheduleItem[] = [];

    for (const rm of visibleRemainingMappings.value) {
      const role = rm.register_template.group_role;

      if (hasOnetimeDate.value && (role === OM_ROLES.onetimeMonth || role === OM_ROLES.onetimeYear))
        continue;

      if (hasOnetimeDate.value && role === OM_ROLES.onetimeDay) {
        items.push({ kind: 'onetimeDate', key: 'onetime-date' });
        continue;
      }

      items.push({ kind: 'register', key: String(rm.measurement_point.id), mapping: rm });
    }

    return items;
  });

  // ── Summary for collapsed state ──────────────────

  const summaryText = computed(() => {
    const startRefMpId = mpForRole(OM_ROLES.startRef)?.id;
    const startRefValue = startRefMpId ? String(configValues[startRefMpId] ?? '0') : '0';
    const refTemplate = mappingForRole(OM_ROLES.startRef)?.register_template;
    const refLabel = refTemplate?.enum_values?.[startRefValue] ?? 'Fixed';

    const durationMpId = mpForRole(OM_ROLES.duration)?.id;
    const durationSeconds = durationMpId ? Number(configValues[durationMpId]) || 0 : 0;

    const parts = [refLabel];
    if (durationSeconds > 0)
      parts.push(formatDuration(durationSeconds));

    return parts.join(' · ');
  });

  // ── Handlers ─────────────────────────────────────

  function handleToggle(value: boolean) {
    const mp = mpForRole(OM_ROLES.enabled);
    if (mp)
      emit('value-change', mp.id, value ? 1 : 0);

    if (value)
      isOpen.value = true;
  }

  function handleRemove() {
    const mp = mpForRole(OM_ROLES.enabled);
    if (mp)
      emit('value-change', mp.id, 0);
  }

  function emitChange(measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']) {
    emit('value-change', measurementPointId, value);
  }

  function isVisible(rm: RegisterMapping) {
    const conditions = rm.register_template.visibility_conditions;
    if (!conditions)
      return true;

    for (const [controllerRole, expectedValues] of Object.entries(conditions)) {
      const controllerMapping = mappings.find(m =>
        m.register_template.group_name === groupName &&
        m.register_template.group_role === controllerRole
      );
      if (!controllerMapping)
        continue;

      const currentValue = String(configValues[controllerMapping.measurement_point.id] ?? '');
      const allowed = Array.isArray(expectedValues) ? expectedValues : [expectedValues];
      if (!allowed.map(String).includes(currentValue))
        return false;
    }
    return true;
  }

  function numericValueFor(mapping: RegisterMapping | undefined) {
    if (!mapping)
      return 0;

    const raw = configValues[mapping.measurement_point.id];
    const n = Number(raw);
    return Number.isNaN(n) ? 0 : n;
  }

  function pad(n: number) {
    return String(n).padStart(2, '0');
  }

  function formatDuration(totalSeconds: number) {
    const h = Math.floor(totalSeconds / 3600);
    const m = Math.floor((totalSeconds % 3600) / 60);
    if (h > 0)
      return `${h}h ${m}m`;

    return `${m}m`;
  }
</script>
