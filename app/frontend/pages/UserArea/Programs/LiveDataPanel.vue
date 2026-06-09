<template>
  <CCard v-if="measurements.length > 0" class="mb-3">
    <CCardHeader class="d-flex align-items-center justify-content-between">
      <h6 class="mb-0">Live data</h6>
      <CButton
        v-if="modbusDeviceId !== null"
        color="light"
        size="sm"
        :disabled="isRefreshing"
        @click="refreshValues">
        <CSpinner v-if="isRefreshing" component="span" size="sm" class="me-1" />
        <CIcon v-else icon="cilReload" class="me-1" />
        Refresh values
      </CButton>
    </CCardHeader>
    <CCardBody>
      <div class="row g-3">
        <div
          v-for="mp in measurements"
          :key="mp.id"
          class="col-sm-6 col-md-4 col-lg-3">
          <MeasurementCard :measurement-point="mp" :enable-control="false" />
        </div>
      </div>
    </CCardBody>
  </CCard>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import { router } from '@inertiajs/vue3';
  import axios from 'axios';
  import MeasurementCard from '@/components/MeasurementCard/index.vue';
  import useAuth from '@/composables/useAuth';
  import { useApiCall } from '@/composables/useApi';
  import type { LiveMeasurementPoint } from '@/types/analytics';

  // Same settle window as the program refresh: the read job is async, so we
  // wait briefly before partial-reloading the measurements.
  const REFRESH_SETTLE_MS = 7000;

  const { measurements, modbusDeviceId } = defineProps<{
    measurements: LiveMeasurementPoint[];
    modbusDeviceId: number | null;
  }>();

  const { routePath } = useAuth();
  const { execute } = useApiCall();

  const isRefreshing = ref(false);

  async function refreshValues() {
    if (modbusDeviceId === null || isRefreshing.value)
      return;

    isRefreshing.value = true;

    const { success } = await execute(
      () => axios.post(routePath('modbus_devices_refresh_values', { id: modbusDeviceId })),
      {
        showSuccessToast: true,
        successMessage: 'Refreshing live values from the device…',
        showErrorToast: true,
        errorTitle: 'Refresh failed'
      }
    );

    if (!success) {
      isRefreshing.value = false;
      return;
    }

    window.setTimeout(() => {
      router.reload({
        only: ['measurements'],
        onFinish: () => { isRefreshing.value = false; }
      });
    }, REFRESH_SETTLE_MS);
  }
</script>
