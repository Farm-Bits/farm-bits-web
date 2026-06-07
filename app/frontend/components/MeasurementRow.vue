<template>
  <CTableRow
    class="align-middle"
    :class="{ 'table-warning': !isConfigured }">
    <CTableDataCell>
      <ConnectionStatusIndicator :measurementPoint="registerMapping.measurement_point" />
    </CTableDataCell>
    <CTableDataCell>
      <div class="d-flex align-items-center gap-2">
        <div>
          <div class="fw-semibold">{{ registerMapping.measurement_point.name }}</div>
          <div
            v-if="registerMapping.measurement_point.description"
            class="text-muted small text-truncate"
            style="max-width: 200px">
            {{ registerMapping.measurement_point.description }}
          </div>
        </div>
        <CBadge v-if="!isConfigured" color="warning" size="sm">
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
      <code class="small">{{ registerLabelOverride ?? registerMapping.register_template.label }}</code>
    </CTableDataCell>
    <CTableDataCell>
      <span v-if="segment" class="badge bg-light text-dark">
        {{ segment.name }}
      </span>
      <span v-else class="text-muted">—</span>
    </CTableDataCell>
    <CTableDataCell>
      <RegisterField
        :model-value="registerMapping.measurement_point.last_value"
        :registerMapping="registerMapping"
        :isEditing="false" />
      <RelativeTime :datetime="registerMapping.measurement_point.last_value_at" />
    </CTableDataCell>
    <CTableDataCell>
      <span v-if="registerMapping.measurement_point.effective_unit" class="text-muted">
        {{ registerMapping.measurement_point.effective_unit }}
      </span>
      <span v-else class="text-muted">—</span>
    </CTableDataCell>
    <CTableDataCell class="text-center">
      <div class="d-flex justify-content-center gap-1">
        <CTooltip v-if="permissions?.measurement_points.update" content="Configure Device">
          <template #toggler="{ on }">
            <CButton
              v-on="on"
              color="primary"
              variant="ghost"
              size="sm"
              @click="$emit('edit', registerMapping)">
              <CIcon icon="cilSettings" />
            </CButton>
          </template>
        </CTooltip>
        <CDropdown class="options-dropdown" variant="btn-group">
          <CDropdownToggle color="light" size="sm" :caret="false">
            <CIcon icon="cilOptions" />
          </CDropdownToggle>
          <CDropdownMenu>
            <CDropdownItem @click="$emit('viewHistory', registerMapping)">
              <CIcon icon="cilHistory" class="me-2" />
              View History
            </CDropdownItem>
            <div v-if="permissions?.measurement_points.update">
              <CDropdownDivider />
              <CDropdownItem
                v-if="isEnabled"
                class="text-danger"
                @click="toggleActive">
                <CIcon icon="cilBan" class="me-2" />
                Disable
              </CDropdownItem>
              <CDropdownItem
                v-else-if="canEnable"
                class="text-success"
                @click="toggleActive">
                <CIcon icon="cilCheckCircle" class="me-2" />
                Enable
              </CDropdownItem>
              <CTooltip v-else content="Configure Device First">
                <template #toggler="{ on }">
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
  import ConnectionStatusIndicator from '@/components/ConnectionStatusIndicator.vue';
  import RegisterField from '@/components/RegisterField.vue';
  import RelativeTime from '@/components/RelativeTime.vue';
  import usePermissions from '@/composables/usePermissions';
  import { useApiCall } from '@/composables/useApi';
  import useAuth from '@/composables/useAuth';
  import type { Segment } from '@/types/location';
  import type { DataCategory, MeasurementPoint, MeasurementSubtype } from '@/types/measurementPoint';
  import type { RegisterMapping } from '@/types/plc';

  const {
    registerMapping,
    segments,
    measurementSubtypes,
    registerLabelOverride
  } = defineProps<{
    registerMapping: RegisterMapping;
    segments: Segment[];
    measurementSubtypes: MeasurementSubtype[];
    registerLabelOverride?: string;
  }>();

  const emit = defineEmits<{
    (e: 'viewHistory', registerMapping: RegisterMapping): void;
    (e: 'edit', registerMapping: RegisterMapping): void;
    (
      e: 'update',
      updatedMeasurementPoint: MeasurementPoint,
      siblingMeasurementPoints: MeasurementPoint[]
    ): void;
  }>();

  const { permissions } = usePermissions();
  const { execute } = useApiCall();
  const { routePath } = useAuth();

  const measurementSubtype = computed(() => {
    if (!registerMapping.measurement_point.measurement_subtype_id) {
      return null;
    }
    return measurementSubtypes.find(
      (subtype) => subtype.id === registerMapping.measurement_point.measurement_subtype_id
    ) ?? null;
  });

  const segment = computed(() => {
    if (!registerMapping.measurement_point.segment_id)
      return null;

    return segments.find((s) => s.id === registerMapping.measurement_point.segment_id);
  });

  const isConfigured = computed(() =>
    registerMapping.measurement_point.active &&
    !!registerMapping.measurement_point.measurement_subtype_id
  );

  const isEnabled = computed(() => registerMapping.measurement_point.active);

  const canEnable = computed(() => !!registerMapping.measurement_point.measurement_subtype_id);

  function formatDataCategory(category: DataCategory): string {
    const categories: Record<DataCategory, string> = {
      'status': 'Status / On-Off',
      'analog': 'Analog Value',
      'counter': 'Counter / Accumulator'
    };
    return categories[category] || category;
  }

  async function toggleActive() {
    const url = routePath('measurement_points_update', {
      id: registerMapping.measurement_point.id
    });
    const willEnable = !registerMapping.measurement_point.active;

    const { success, data } = await execute<{
      measurement_point: MeasurementPoint;
      sibling_measurement_points: MeasurementPoint[];
    }>(
      () => axios.put(url, { measurement_point: { active: willEnable } }),
      {
        showSuccessToast: true,
        successMessage: `${registerMapping.measurement_point.name} updated successfully`,
        showErrorToast: true,
        errorTitle: 'Error'
      }
    );

    if (success)
      emit('update', data.measurement_point, data.sibling_measurement_points);
  }
</script>
