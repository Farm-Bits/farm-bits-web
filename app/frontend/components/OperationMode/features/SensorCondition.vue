<template>
  <div
    class="border rounded mb-2"
    :class="isEnabled ? 'border-success-subtle' : ''">
    <!-- Header -->
    <div
      v-if="enabledMapping"
      class="d-flex align-items-center gap-2 px-3 py-2"
      role="button"
      @click="isOpen = !isOpen">
      <template v-if="removable">
        <span class="flex-grow-1 fw-medium">
          {{ label }} {{ conditionNumber }}
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
          {{ label }} {{ conditionNumber }}
          <template v-if="!isOpen && isEnabled && summaryText">
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
      <!-- Source MP picker (composite: drives source_type + source_io_number) -->
      <div class="mb-2">
        <label class="form-label small text-body-secondary">Monitor Device</label>
        <CFormSelect
          :model-value="selectedSourceKey"
          @update:model-value="handleSourceChange">
          <option value="">Select a device...</option>
          <optgroup
            v-for="group in sourceGroups"
            :key="group.label"
            :label="group.label">
            <option
              v-for="source in group.sources"
              :key="source.key"
              :value="source.key">
              {{ source.label }}
            </option>
          </optgroup>
        </CFormSelect>
      </div>

      <!-- Current value of selected source -->
      <div
        v-if="selectedSourceInfo"
        class="small bg-success-subtle text-body-secondary rounded px-2 py-1 mb-2">
        Current: <strong class="text-body">{{ selectedSourceInfo.last_value ?? '—' }}{{ selectedSourceInfo.effective_unit ? ` ${selectedSourceInfo.effective_unit}` : '' }}</strong>
      </div>

      <!-- Operator, threshold, hysteresis — generic fields -->
      <div class="row g-2">
        <div
          v-for="rm in visibleGenericMappings"
          :key="rm.measurement_point.id"
          class="col-4">
          <CFormLabel class="fw-semibold d-flex align-items-center gap-2">
            {{ rm.register_template.name }}
            <CTooltip
              v-if="rm.register_template.description"
              :content="rm.register_template.description">
              <template #toggler="{ on }">
                <CIcon v-on="on" icon="cilInfo" size="sm" class="text-muted" />
              </template>
            </CTooltip>
          </CFormLabel>
          <RegisterField
            :model-value="configValues[rm.measurement_point.id]"
            :register-mapping="rm"
            :is-editing="true"
            @update:model-value="emitChange(rm.measurement_point.id, $event)" />
        </div>
      </div>

      <!-- Any extra fields beyond known roles -->
      <div
        v-for="rm in extraMappings"
        :key="rm.measurement_point.id"
        class="mb-2 mt-2">
        <CFormLabel class="fw-semibold d-flex align-items-center gap-2">
          {{ rm.register_template.name }}
          <CTooltip
            v-if="rm.register_template.description"
            :content="rm.register_template.description">
            <template #toggler="{ on }">
              <CIcon v-on="on" icon="cilInfo" size="sm" class="text-muted" />
            </template>
          </CTooltip>
        </CFormLabel>
        <RegisterField
          :model-value="configValues[rm.measurement_point.id]"
          :register-mapping="rm"
          :is-editing="true"
          @update:model-value="emitChange(rm.measurement_point.id, $event)" />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed, ref } from 'vue';
  import RegisterField from '@/components/RegisterField.vue';
  import { useGroupRegisters } from '@/composables/useGroupRegisters';
  import type { ConfigValues } from '@/composables/useConfigurationValues';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { RegisterMapping, SourceIoInfo } from '@/types/plc';
  import { OM_ROLES } from '@/types/operationMode';

  const { mappings, groupName, conditionNumber, label, configValues, availableSources, removable = false } = defineProps<{
    mappings: RegisterMapping[];
    groupName: string;
    conditionNumber: number;
    label: string;
    configValues: ConfigValues;
    availableSources: SourceIoInfo[];
    removable?: boolean;
  }>();

  const emit = defineEmits<{
    (e: 'value-change', measurementPointId: MeasurementPoint['id'], value: MeasurementPoint['last_value']): void;
  }>();

  const mappingsRef = computed(() => mappings);
  const groupNameRef = computed(() => groupName);
  const { getValue, mpForRole, mappingForRole, mappingsExcept } = useGroupRegisters(mappingsRef, groupNameRef);

  const isOpen = ref(removable);

  // ── State ────────────────────────────────────────

  const isEnabled = computed(() => {
    const mpId = mpForRole(OM_ROLES.enabled)?.id;
    if (!mpId)
      return false;

    return String(configValues[mpId]) === '1';
  });

  const enabledMapping = computed(() => mappingForRole(OM_ROLES.enabled));

  // ── Source selection (composite: source_type + source_io_number) ──

  const selectedSourceInfo = computed(() => {
    const typeMpId = mpForRole(OM_ROLES.sourceType)?.id;
    const numberMpId = mpForRole(OM_ROLES.sourceIoNumber)?.id;
    if (!typeMpId || !numberMpId)
      return null;

    const typeVal = Number(configValues[typeMpId]);
    const numberVal = Number(configValues[numberMpId]);
    if (!typeVal || !numberVal || Number.isNaN(typeVal) || Number.isNaN(numberVal))
      return null;

    return availableSources.find(
      s => s.source_type === typeVal && s.io_number === numberVal
    ) ?? null;
  });

  const selectedSourceKey = computed(() => {
    const info = selectedSourceInfo.value;
    if (!info)
      return '';

    return `${info.source_type}_${info.io_number}`;
  });

  const sourceGroups = computed(() => {
    const groups = new Map<string, { label: string; sources: { key: string; label: string }[] }>();

    for (const source of availableSources) {
      const commType = source.communication_type;
      const typeLabel = commType.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());

      if (!groups.has(commType))
        groups.set(commType, { label: typeLabel, sources: [] });

      groups.get(commType)!.sources.push({
        key: `${source.source_type}_${source.io_number}`,
        label: source.label,
      });
    }

    return [...groups.values()];
  });

  function handleSourceChange(key: string) {
    if (!key)
      return;

    const [typeStr, numberStr] = key.split('_');
    const typeMp = mpForRole(OM_ROLES.sourceType);
    const numberMp = mpForRole(OM_ROLES.sourceIoNumber);

    if (typeMp)
      emit('value-change', typeMp.id, Number(typeStr));

    if (numberMp)
      emit('value-change', numberMp.id, Number(numberStr));
  }

  // ── Generic fields (operator, threshold, hysteresis) ──

  const compositeRoles = [
    OM_ROLES.enabled, OM_ROLES.sourceType, OM_ROLES.sourceIoNumber,
  ];

  const genericMappings = computed(() => {
    const genericRoles = [OM_ROLES.operator, OM_ROLES.threshold, OM_ROLES.hysteresis];
    return genericRoles
      .map((role) => mappingForRole(role))
      .filter((rm): rm is RegisterMapping => !!rm);
  });

  const visibleGenericMappings = computed(() =>
    genericMappings.value.filter(rm => isVisible(rm))
  );

  const extraMappings = computed(() =>
    mappingsExcept(
      ...compositeRoles,
      OM_ROLES.operator, OM_ROLES.threshold, OM_ROLES.hysteresis
    )
  );

  // ── Summary for collapsed state ──────────────────

  const summaryText = computed(() => {
    if (!selectedSourceInfo.value)
      return null;

    const operatorTemplate = mappingForRole(OM_ROLES.operator)?.register_template;
    const operatorMpId = mpForRole(OM_ROLES.operator)?.id;
    const operatorValue = operatorMpId ? String(configValues[operatorMpId] ?? '0') : '0';
    const operatorLabel = operatorTemplate?.enum_values?.[operatorValue] ?? '?';

    const thresholdMpId = mpForRole(OM_ROLES.threshold)?.id;
    const thresholdValue = thresholdMpId ? configValues[thresholdMpId] : null;

    return `${selectedSourceInfo.value.label.split(':')[0]}: ${operatorLabel} ${thresholdValue ?? '?'}`;
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
</script>
