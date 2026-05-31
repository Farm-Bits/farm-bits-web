<template>
  <div>
    <p class="text-muted mb-4">
      This controller has been delivered to your site but isn't set up yet.
      Give it a name and choose which gateway it connects to.
    </p>

    <div class="bg-light rounded p-3 mb-4 small">
      <div class="row g-2">
        <div class="col-6">
          <span class="text-muted">Model:</span>
          <strong class="ms-1">{{ row.details.model?.full_name || '—' }}</strong>
        </div>
        <div class="col-6">
          <span class="text-muted">Firmware:</span>
          <strong class="ms-1">{{ row.details.modbus_firmware_version?.name || '—' }}</strong>
        </div>
        <div class="col-6">
          <span class="text-muted">Modbus slave:</span>
          <strong class="ms-1">{{ row.details.slave_id }}</strong>
        </div>
        <div class="col-6">
          <span class="text-muted">Serial:</span>
          <strong class="ms-1 font-monospace">{{ row.details.serial_number }}</strong>
        </div>
      </div>
    </div>

    <CForm @submit.prevent="submit">
      <div class="mb-3">
        <CFormLabel>Name <span class="text-danger">*</span></CFormLabel>
        <CFormInput
          v-model="form.name"
          placeholder="e.g. Greenhouse North"
          required />
        <CFormText>How this controller will appear in the equipment list.</CFormText>
      </div>

      <div class="mb-3">
        <CFormLabel>Connected to gateway <span class="text-danger">*</span></CFormLabel>
        <CFormSelect v-model="form.gateway_id" required>
          <option value="" selected disabled hidden>— Select a gateway —</option>
          <option v-for="gw in availableGateways" :key="gw.id" :value="String(gw.id)">
            {{ gw.name }}
          </option>
        </CFormSelect>
        <CFormText v-if="availableGateways.length === 0" class="text-warning">
          No active gateways available. Set up a gateway first.
        </CFormText>
      </div>

      <div v-if="error" class="alert alert-danger small">{{ error }}</div>

      <div class="d-flex justify-content-end gap-2 mt-4">
        <CButton color="secondary" variant="outline" @click="$emit('cancel')" :disabled="submitting">
          Cancel
        </CButton>
        <CButton
          color="primary"
          type="submit"
          :disabled="submitting || !canSubmit">
          <span v-if="submitting" class="spinner-border spinner-border-sm me-2" />
          Set up controller
        </CButton>
      </div>
    </CForm>
  </div>
</template>

<script lang="ts" setup>
  import { computed, reactive, ref } from 'vue';
  import axios from 'axios';
  import { useApiCall } from '@/composables/useApi';
  import useAuth from '@/composables/useAuth';
  import type { FlatPlcRow, EligibleHost } from '../types';

  const props = defineProps<{
    row: FlatPlcRow;
    availableGateways: EligibleHost[];
  }>();
  const emit = defineEmits<{
    (e: 'success'): void;
    (e: 'cancel'): void;
  }>();

  const { execute } = useApiCall();
  const { routePath } = useAuth();

  const form = reactive<{ name: string; gateway_id: string }>({
    name: props.row.name || '',
    gateway_id: '',
  });

  const submitting = ref(false);
  const error = ref<string | null>(null);

  const canSubmit = computed(() => {
    return form.name.trim().length > 0 && form.gateway_id !== '';
  });

  async function submit() {
    if (!canSubmit.value)
      return;

    submitting.value = true;
    error.value = null;

    const url = routePath('plcs_update', { id: props.row.id });
    const result = await execute(
      () => axios.put(url, {
        plc: {
          name: form.name.trim(),
          gateway_id: Number(form.gateway_id),
          active: true,
        },
      }),
      {
        showSuccessToast: true,
        successMessage: 'Controller set up successfully',
        showErrorToast: false,
      }
    );

    submitting.value = false;

    if (result.success) {
      emit('success');
    } else {
      error.value = result.error.error || 'Could not set up controller. Please try again.';
    }
  }
</script>
