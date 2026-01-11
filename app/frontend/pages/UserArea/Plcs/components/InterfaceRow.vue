<template>
  <CTableRow
    v-if="activeRegisterMapping"
    class="align-middle"
    :class="{ 'table-warning': !isConfigured(activeRegisterMapping.measurement_point) }">
    <CTableDataCell>
      <StatusIndicator :point="activeRegisterMapping.measurement_point" />
    </CTableDataCell>
    <CTableDataCell>
      <div class="d-flex align-items-center gap-2">
        <div>
          <div class="fw-semibold">{{ activeRegisterMapping.measurement_point.name }}</div>
          <div v-if="activeRegisterMapping.measurement_point.description" class="text-muted small text-truncate" style="max-width: 200px">
            {{ activeRegisterMapping.measurement_point.description }}
          </div>
        </div>
        <CBadge v-if="!isConfigured(activeRegisterMapping.measurement_point)" color="warning" size="sm">
          Not Configured
        </CBadge>
      </div>
    </CTableDataCell>
    <CTableDataCell>
      <div v-if="measurementSubtype">
        <span class="fw-medium">{{ measurementSubtype.full_name }}</span>
        <div class="text-muted small">
          {{ formatDataCategory(measurementSubtype.data_category) }}
        </div>
      </div>
      <span v-else class="text-muted">—</span>
    </CTableDataCell>
    <CTableDataCell>
      <code class="small">{{ interface.name }}</code>
    </CTableDataCell>
    <CTableDataCell>
      <span v-if="segment" class="badge bg-light text-dark">
        {{ segment.name }}
      </span>
      <span v-else class="text-muted">—</span>
    </CTableDataCell>
    <CTableDataCell>
      <ValueDisplay :point="activeRegisterMapping.measurement_point" />
    </CTableDataCell>
    <CTableDataCell>
      <span v-if="activeRegisterMapping.measurement_point.effective_unit" class="text-muted">
        {{ activeRegisterMapping.measurement_point.effective_unit }}
      </span>
      <span v-else class="text-muted">—</span>
    </CTableDataCell>
    <CTableDataCell class="text-center">
      <div class="d-flex justify-content-center gap-1">
        <CTooltip content="Configure Device">
          <template #toggler="{ id, on }">
            <span v-on="on" class="d-inline-block">
              <CButton
                color="primary"
                variant="ghost"
                size="sm"
                @click="$emit('edit', interface, measurementRegisterMappings)">
                <CIcon icon="cilPencil" />
              </CButton>
            </span>
          </template>
        </CTooltip>
        <CDropdown variant="btn-group">
          <CDropdownToggle
            color="light"
            size="sm"
            :caret="false">
            <CIcon icon="cilOptions" />
          </CDropdownToggle>
          <CDropdownMenu>
            <CDropdownItem @click="viewHistory(activeRegisterMapping.measurement_point)">
              <CIcon icon="cilHistory" class="me-2" />
              View History
            </CDropdownItem>
            <CDropdownDivider />
            <CDropdownItem
              class="text-danger"
              @click="toggleActive(activeRegisterMapping.measurement_point)">
              <CIcon :icon="activeRegisterMapping.measurement_point.active ? 'cilBan' : 'cilCheckCircle'" class="me-2" />
              {{ activeRegisterMapping.measurement_point.active ? 'Disable' : 'Enable' }}
            </CDropdownItem>
          </CDropdownMenu>
        </CDropdown>
      </div>
    </CTableDataCell>
  </CTableRow>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import StatusIndicator from './StatusIndicator.vue';
  import ValueDisplay from './ValueDisplay.vue';
  import type { Segment } from '@/types/location';
  import { isDataCategory, type DataCategory, type MeasurementPoint, type MeasurementSubtype } from '@/types/measurementPoint';
  import type { InterfaceWithMeasurementPoints } from '@/types/plc';

  const props = defineProps<{
    interface: InterfaceWithMeasurementPoints;
    segments: Segment[];
    measurementSubtypes: MeasurementSubtype[];
  }>();

  const emit = defineEmits<{
    (e: 'edit', iface: InterfaceWithMeasurementPoints, registerMappings: InterfaceWithMeasurementPoints['register_mappings']): void;
  }>();

  const measurementRegisterMappings = computed(() => {
    return props.interface.register_mappings.filter((mapping) => {
      return isDataCategory(mapping.category);
    });
  });

  const activeRegisterMapping = computed(() => {
    if (measurementRegisterMappings.value.length === 0)
      return null;

    const mp = measurementRegisterMappings.value.find((registerMapping) => {
      return registerMapping.measurement_point.active;
    });
    return mp || measurementRegisterMappings.value[0];
  });

  const measurementSubtype = computed(() => {
    if (!activeRegisterMapping.value || !activeRegisterMapping.value.measurement_point.measurement_subtype_id)
      return null;

    return props.measurementSubtypes.find((subtype) => subtype.id === activeRegisterMapping.value!.measurement_point.measurement_subtype_id)
  });

  const segment = computed(() => {
    if (!activeRegisterMapping.value || !activeRegisterMapping.value.measurement_point.segment_id)
      return null;

    return props.segments.find((segment) => segment.id === activeRegisterMapping.value!.measurement_point.segment_id)
  });

  function isConfigured(point: MeasurementPoint) {
    return !!point.measurement_subtype_id;
  }

  function formatDataCategory(category: DataCategory): string {
    const categories: Record<DataCategory, string> = {
      'status': 'Status / On-Off',
      'analog': 'Analog Value',
      'counter': 'Counter / Accumulator'
    };
    return categories[category] || category;
  }

  function viewHistory(point: MeasurementPoint) {
    console.log('View history for:', point.id);
  }

  async function toggleActive(point: MeasurementPoint) {
    console.log('Toggle active for:', point.id);
  }
</script>

<style scoped>
  .measurement-points-table {
    font-size: 0.875rem;
  }

  .measurement-points-table :deep(th) {
    font-weight: 600;
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.025em;
    color: #6b7280;
    border-bottom: 2px solid #e5e7eb;
  }

  .measurement-points-table :deep(td) {
    vertical-align: middle;
    border-bottom: 1px solid #f3f4f6;
  }

  .measurement-points-table :deep(tr:hover) {
    background-color: #f9fafb;
  }
</style>
