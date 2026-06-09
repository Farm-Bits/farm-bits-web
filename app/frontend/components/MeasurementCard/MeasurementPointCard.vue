<template>
  <div
    class="mp-card"
    role="button"
    @click="emit('click', measurementPoint)">
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
    </div>

    <!-- <div class="mp-card__meta d-flex align-items-center gap-2">
      <span class="small text-body-secondary">{{ measurementPoint.plc_name }}</span>
      <span class="small text-body-secondary">·</span>
      <span class="small text-body-secondary">{{ measurementPoint.register_template.name }}</span>
      <span v-if="measurementPoint.last_value_at" class="small text-body-secondary ms-auto">
        <RelativeTime :datetime="measurementPoint.last_value_at" />
      </span>
    </div> -->

    <div class="mp-card__value flex items-center gap-2">
      <ValueDisplay
        :value="measurementPoint.last_value"
        :valueFormat="measurementPoint.register_template.value_format"
        :unit="measurementPoint.effective_unit"
        :enumValues="measurementPoint.register_template.enum_values"
        placeholder="No data"
        size="default" />
      <p v-show="statusLabels !== ''" class="text-body-secondary small mb-0">({{ statusLabels }})</p>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed, toRef } from 'vue';
  import ConnectionStatusIndicator from '@/components/ConnectionStatusIndicator.vue';
  import ValueDisplay from '@/components/ValueDisplay.vue';
  import { useRegisterVisibility } from '@/composables/useRegisterVisibility';
  import { getDisplayValue } from '@/utils/valueConverters';
  import type { LiveMeasurementPoint } from '@/types/analytics';
  import type { RegisterMapping } from '@/types/plc';
  import type { ConfigValues } from '@/composables/useConfigurationValues';
  import { iconMap } from '@/assets/icons/measurement';

  const { measurementPoint, interfaceStatuses, registerMappings } = defineProps<{
    measurementPoint: LiveMeasurementPoint;
    interfaceStatuses: LiveMeasurementPoint[];
    registerMappings: RegisterMapping[];
  }>();

  const emit = defineEmits<{
    (e: 'click', mp: LiveMeasurementPoint): void;
  }>();

  const { isVisible } = useRegisterVisibility(
    toRef(() => registerMappings),
    toRef(() => interfaceStatuses.reduce((acc: ConfigValues, s) => {
      acc[s.id] = s.last_value;
      return acc;
    }, {}))
  );

  const statusBadges = computed<{ label: string; color: string }[]>(() => {
    const badges: { label: string; color: string }[] = [];

    for (const s of interfaceStatuses) {
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
</script>

<style scoped>
  .mp-card {
    padding: 0.75rem;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    cursor: pointer;
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

  .mp-card__name {
    font-weight: 600;
    font-size: 0.875rem;
    color: #374151;
  }

  .mp-card__value {
    margin: 0.25rem 0;
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
