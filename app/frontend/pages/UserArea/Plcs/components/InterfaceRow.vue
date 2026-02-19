<template>
  <CTableRow
    v-if="activeRegisterMapping"
    class="align-middle"
    :class="{ 'table-warning': !isConfigured(activeRegisterMapping.measurement_point) }">
    <CTableDataCell>
      <StatusIndicator :measurementPoint="activeRegisterMapping.measurement_point" />
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
      <code class="small">{{ iface.name }}</code>
    </CTableDataCell>
    <CTableDataCell>
      <span v-if="segment" class="badge bg-light text-dark">
        {{ segment.name }}
      </span>
      <span v-else class="text-muted">—</span>
    </CTableDataCell>
    <CTableDataCell>
      <RegisterField
        v-model="activeRegisterMapping.measurement_point.last_value"
        :registerMapping="activeRegisterMapping"
        :isEditing="false" />
      <RelativeTime
        :datetime="activeRegisterMapping.measurement_point.last_value_at" />
    </CTableDataCell>
    <CTableDataCell>
      <span v-if="activeRegisterMapping.measurement_point.effective_unit" class="text-muted">
        {{ activeRegisterMapping.measurement_point.effective_unit }}
      </span>
      <span v-else class="text-muted">—</span>
    </CTableDataCell>
    <CTableDataCell class="text-center">
      <div class="d-flex justify-content-center gap-1">
        <CTooltip v-if="permissions?.measurement_points.update" content="Configure Device">
          <template #toggler="{ id, on }">
            <CButton
              v-on="on"
              color="primary"
              variant="ghost"
              size="sm"
              @click="$emit('edit', iface)">
              <CIcon icon="cilSettings" />
            </CButton>
          </template>
        </CTooltip>
        <CDropdown class="options-dropdown" variant="btn-group">
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
            <div v-if="permissions?.measurement_points.update">
              <CDropdownDivider />
              <CDropdownItem
                v-if="isEnabled(activeRegisterMapping.measurement_point)"
                class="text-danger"
                @click="toggleActive(activeRegisterMapping.measurement_point)">
                <CIcon icon="cilBan" class="me-2" />
                Disable
              </CDropdownItem>
              <CDropdownItem
                v-else-if="canEnable(activeRegisterMapping.measurement_point)"
                class="text-danger"
                @click="toggleActive(activeRegisterMapping.measurement_point)">
                <CIcon icon="cilCheckCircle" class="me-2" />
                Enable
              </CDropdownItem>
              <CTooltip v-else content="Configure Device First">
                <template #toggler="{ id, on }">
                  <span v-on="on" class="d-inline-block">
                    <CDropdownItem disabled>
                      <CIcon icon="cilCheckCircle" class="me-2" />
                      Enable
                    </CDropdownItem>
                  </span>
                </template>
              </CTooltip>
            </div>
          </CDropdownMenu>
        </CDropdown>
      </div>
    </CTableDataCell>
  </CTableRow>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import axios from 'axios';
  import StatusIndicator from './StatusIndicator.vue';
  import RegisterField from '@/components/RegisterField.vue';
  import RelativeTime from '@/components/RelativeTime.vue';
  import usePermissions from '@/composables/usePermissions';
  import { useApiCall } from '@/composables/useApi';
  import { ROUTES } from '@/types/permissions';
  import type { Segment } from '@/types/location';
  import { isDataCategory, type DataCategory, type MeasurementPoint, type MeasurementSubtype } from '@/types/measurementPoint';
  import type { InterfaceWithMeasurementPoints } from '@/types/plc';

  const {
    iface,
    segments,
    measurementSubtypes
  } = defineProps<{
    iface: InterfaceWithMeasurementPoints;
    segments: Segment[];
    measurementSubtypes: MeasurementSubtype[];
  }>();

  const emit = defineEmits<{
    (e: 'edit', iface: InterfaceWithMeasurementPoints): void;
    (
      e: 'update',
      updatedMeasurementPoint: MeasurementPoint,
      siblingMeasurementPoints: MeasurementPoint[]
    ): void;
  }>();

  const { permissions } = usePermissions();
  const { execute } = useApiCall();

  const measurementRegisterMappings = computed(() => {
    return iface.register_mappings.filter((mapping) => {
      return isDataCategory(mapping.register_template.category);
    });
  });

  const activeRegisterMapping = computed(() => {
    if (measurementRegisterMappings.value.length === 0)
      return null;

    const mpActive = measurementRegisterMappings.value.find((registerMapping) => {
      return registerMapping.measurement_point.active;
    });
    if (mpActive)
      return mpActive;

    const mpConfigured = measurementRegisterMappings.value.find((registerMapping) => {
      return !!registerMapping.measurement_point.measurement_subtype_id;
    });
    return mpConfigured || measurementRegisterMappings.value[0];
  });

  const measurementSubtype = computed(() => {
    if (!activeRegisterMapping.value || !activeRegisterMapping.value.measurement_point.measurement_subtype_id)
      return null;

    return measurementSubtypes.find((subtype) =>
      subtype.id === activeRegisterMapping.value!.measurement_point.measurement_subtype_id
    ) || null;
  });

  const segment = computed(() => {
    if (!activeRegisterMapping.value || !activeRegisterMapping.value.measurement_point.segment_id)
      return null;

    return segments.find((segment) => segment.id === activeRegisterMapping.value!.measurement_point.segment_id)
  });

  function isConfigured(measurementPoint: MeasurementPoint) {
    return measurementPoint.active && !!measurementPoint.measurement_subtype_id;
  }

  function isEnabled(measurementPoint: MeasurementPoint) {
    return measurementPoint.active;
  }

  function canEnable(measurementPoint: MeasurementPoint) {
    return !!measurementPoint.measurement_subtype_id;
  }

  function formatDataCategory(category: DataCategory): string {
    const categories: Record<DataCategory, string> = {
      'status': 'Status / On-Off',
      'analog': 'Analog Value',
      'counter': 'Counter / Accumulator'
    };
    return categories[category] || category;
  }

  function viewHistory(measurementPoint: MeasurementPoint) {
    console.log('View history for:', measurementPoint.id);
  }

  async function toggleActive(measurementPoint: MeasurementPoint) {
    const url = ROUTES.measurement_points_update.path.replace(':id', String(measurementPoint.id));
    const willEnable = !measurementPoint.active;
    const measurementPointData = {
      // data_collection_enabled: willEnable,
      // polling_interval_seconds: willEnable ? 300 : null,
      active: willEnable
    };

    const { success, data } = await execute<{
      measurement_point: MeasurementPoint,
      sibling_measurement_points: MeasurementPoint[]
    }>(
      () => axios.put(url, { measurement_point: measurementPointData }),
      {
        showSuccessToast: true,
        successMessage: `Interface ${iface.name} updated successfully`,
        showErrorToast: true,
        errorTitle: 'Error'
      }
    );

    if (success) {
      emit(
        'update',
        data.measurement_point,
        data.sibling_measurement_points
      );
    }
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
