<template>
  <CForm @submit.prevent="submit">
    <div class="mb-3">
      <CFormLabel>Name <span class="text-danger">*</span></CFormLabel>
      <CFormInput v-model="form.name" required />
    </div>

    <div class="mb-3">
      <CFormLabel>Connected to gateway <span class="text-danger">*</span></CFormLabel>
      <CFormSelect v-model="form.gateway_id" required>
        <option value="" selected disabled hidden>— Select a gateway —</option>
        <option v-for="gw in availableGateways" :key="gw.id" :value="String(gw.id)">
          {{ gw.name }}
        </option>
      </CFormSelect>
    </div>

    <div class="bg-light rounded p-3 mb-4 small">
      <div class="text-muted mb-2">Hardware details</div>
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

    <div v-if="error" class="alert alert-danger small">{{ error }}</div>

    <div class="d-flex justify-content-end gap-2">
      <CButton color="secondary" variant="outline" @click="$emit('cancel')" :disabled="submitting">
        Cancel
      </CButton>
      <CButton color="primary" type="submit" :disabled="submitting || !canSubmit">
        <span v-if="submitting" class="spinner-border spinner-border-sm me-2" />
        Save
      </CButton>
    </div>
  </CForm>
</template>

<script lang="ts" setup>
  import { computed, reactive, ref } from 'vue';
  import axios from 'axios';
  import { useApiCall } from '@/composables/useApi';
  import { ROUTES } from '@/types/permissions';
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

  const form = reactive<{ name: string; gateway_id: string }>({
    name: props.row.name || '',
    gateway_id: props.row.details.gateway_id !== null ? String(props.row.details.gateway_id) : '',
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

    const url = ROUTES.plcs_update.path.replace(':id', String(props.row.id));
    const result = await execute(
      () => axios.put(url, {
        plc: {
          name: form.name.trim(),
          gateway_id: Number(form.gateway_id),
        },
      }),
      { showSuccessToast: true, successMessage: 'Controller updated', showErrorToast: false }
    );

    submitting.value = false;
    if (result.success)
      emit('success');
    else
      error.value = result.error.error || 'Could not save controller.';
  }
</script>
