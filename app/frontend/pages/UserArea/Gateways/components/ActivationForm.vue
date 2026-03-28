<template>
  <CForm @submit.prevent="handleSubmit">
    <div class="mb-3">
      <CFormLabel class="fw-semibold">Select Gateway</CFormLabel>
      <CFormSelect
        v-model="formData.gateway_id"
        :invalid="!!errors.gateway_id"
        @change="handleGatewaySelect">
        <option value="">-- Select a gateway --</option>
        <option
          v-for="gateway in availableGateways"
          :key="gateway.id"
          :value="gateway.id">
          {{ gateway.label }} ({{ gateway.name }})
        </option>
      </CFormSelect>
      <CFormFeedback v-if="errors.gateway_id" invalid>
        {{ errors.gateway_id }}
      </CFormFeedback>
    </div>

    <!-- Selected Gateway Details Card -->
    <div v-if="selectedGatewayDetails">
      <GatewayDetailsForm
        :model-value="formData"
        :gateway="selectedGatewayDetails"
        :availablePlcs="availablePlcs" />
    </div>

    <!-- PLC Assignment Section -->
    <div class="pt-3 mb-3">
      <PlcAssignmentManager
        v-model="formData.plc_assignments"
        :availablePlcs="availablePlcs" />
    </div>

    <!-- Form Actions -->
    <div class="d-flex justify-content-end gap-2">
      <CButton color="secondary" @click="$emit('cancel')">
        Cancel
      </CButton>
      <CButton
        type="submit"
        color="primary"
        :disabled="processing">
        <CSpinner v-if="processing" size="sm" class="me-2" />
        Activate Gateway
      </CButton>
    </div>
  </CForm>
</template>

<script lang="ts" setup>
  import { ref, reactive, computed, nextTick } from 'vue';
  import axios from 'axios';
  import GatewayDetailsForm from './GatewayDetailsForm.vue';
  import PlcAssignmentManager from './PlcAssignmentManager.vue';
  import { useApiCall } from '@/composables/useApi';
  import { ROUTES } from '@/types/permissions';
  import type { Gateway, GatewayAssigned } from '@/types/gateway';
  import type { Plc } from '@/types/plc';

  const props = defineProps<{
    availableGateways: Gateway[];
    availablePlcs: Plc[];
  }>();
  const emit = defineEmits<{
    (e: 'cancel'): void;
    (e: 'success', site: GatewayAssigned): void;
  }>();

  const { execute } = useApiCall();

  const formData = reactive({
    gateway_id: '',
    customName: '',
    plc_assignments: [] as (Plc & { customName: string })[]
  });

  const errors = ref<Record<string, string>>({});
  const processing = ref(false);

  const selectedGatewayDetails = computed(() => {
    if (!formData.gateway_id)
      return null;

    return props.availableGateways.find((t) => t.id === parseInt(formData.gateway_id));
  });

  function handleGatewaySelect() {
    delete errors.value.gateway_id;
    nextTick(() => {
      formData.customName = selectedGatewayDetails.value?.name || '';
    });
  }

  async function handleSubmit() {
    processing.value = true;
    errors.value = {};

    const selectedGateway = props.availableGateways.find(
      (t) => t.id === parseInt(formData.gateway_id)
    );

    if (!selectedGateway) {
      errors.value.gateway_id = 'Please select a gateway';
      processing.value = false;
      return;
    }

    const submitData = {
      gateway: {
        name: formData.customName,
        iccid: selectedGateway.iccid,
        phone_number: selectedGateway.phone_number,
        active: true,
        plc_assignments: formData.plc_assignments
          .filter((a) => a.id)
          .map((a) => ({ id: a.id, name: a.customName }))
      }
    };

    const url = ROUTES.gateways_update.path.replace(':id', String(selectedGateway.id));
    const { success, data } = await execute<GatewayAssigned>(
      () => axios.put(url, submitData),
      {
        showSuccessToast: true,
        successMessage: 'Gateway added successfully',
        showErrorToast: true,
        errorTitle: 'Add Gateway Error'
      }
    );

    if (success)
      emit('success', data);

    processing.value = false;
  }
</script>

<style scoped>
</style>
