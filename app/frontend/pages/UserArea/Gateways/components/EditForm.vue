<template>
  <CForm @submit.prevent="handleSubmit">
    <!-- Gateway Details -->
    <GatewayDetailsForm
      :model-value="formData"
      :gateway="gateway"
      :available-plcs="localAvailablePlcs" />

    <!-- PLC Assignment Section -->
    <div class="pt-3 mb-3">
      <PlcAssignmentManager
        v-model="formData.plc_assignments"
        :available-plcs="localAvailablePlcs" />
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
        Update Gateway
      </CButton>
    </div>
  </CForm>
</template>

<script lang="ts" setup>
  import { ref, reactive, onMounted } from 'vue';
  import axios from 'axios';
  import GatewayDetailsForm from './GatewayDetailsForm.vue';
  import PlcAssignmentManager from './PlcAssignmentManager.vue';
  import { useApiCall } from '@/composables/useApi';
  import { ROUTES } from '@/types/permissions';
  import type { GatewayAssigned } from '@/types/gateway';
  import type { Plc } from '@/types/plc';

  const props = defineProps<{
    gateway: GatewayAssigned;
    availablePlcs: Plc[];
  }>();
  const emit = defineEmits<{
    (e: 'cancel'): void;
    (e: 'success', oldGateway: GatewayAssigned, newGateway: GatewayAssigned): void;
  }>();

  const { execute } = useApiCall();

  const formData = reactive({
    customName: '',
    plc_assignments: [] as (Plc & { customName: string })[]
  });

  const localAvailablePlcs = ref<Plc[]>([]);
  const errors = ref<Record<string, string>>({});
  const processing = ref(false);

  onMounted(() => {
    formData.customName = props.gateway.name || '';

    if (props.gateway.plcs) {
      formData.plc_assignments = props.gateway.plcs.map((plc) => ({
        ...plc,
        customName: plc.name
      }));
    }

    localAvailablePlcs.value = [
      ...props.availablePlcs,
      ...props.gateway.plcs
    ];
  });

  async function handleSubmit() {
    processing.value = true;
    errors.value = {};

    const submitData = {
      gateway: {
        name: formData.customName,
        plc_assignments: formData.plc_assignments
          .filter((a) => a.id)
          .map((a) => ({ id: a.id, name: a.customName }))
      }
    };

    const url = ROUTES.gateways_update.path.replace(':id', String(props.gateway.id));
    const { success, data } = await execute<GatewayAssigned>(
      () => axios.put(url, submitData),
      {
        showSuccessToast: true,
        successMessage: 'Gateway updated successfully',
        showErrorToast: true,
        errorTitle: 'Update Gateway Error'
      }
    );

    if (success)
      emit('success', props.gateway, data);

    processing.value = false;
  }
</script>

<style scoped>
</style>
