<template>
  <CForm @submit.prevent="submit">
    <div class="mb-3">
      <CFormLabel>Name <span class="text-danger">*</span></CFormLabel>
      <CFormInput
        v-model="form.name"
        :invalid="!!error"
        required />
    </div>

    <div class="bg-light rounded p-3 mb-4 small">
      <div class="text-muted mb-2">Hardware details</div>
      <div class="row g-2">
        <div class="col-6">
          <span class="text-muted">Manufacturer:</span>
          <strong class="ms-1">{{ row.details.model?.full_name || '—' }}</strong>
        </div>
        <div class="col-6">
          <span class="text-muted">IMEI:</span>
          <strong class="ms-1 font-monospace">{{ row.details.imei }}</strong>
        </div>
        <div class="col-6">
          <span class="text-muted">Phone:</span>
          <strong class="ms-1">{{ row.details.phone_number || '—' }}</strong>
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
      <CButton color="primary" type="submit" :disabled="submitting || !form.name.trim()">
        <span v-if="submitting" class="spinner-border spinner-border-sm me-2" />
        Save
      </CButton>
    </div>
  </CForm>
</template>

<script lang="ts" setup>
  import { reactive, ref } from 'vue';
  import axios from 'axios';
  import { useApiCall } from '@/composables/useApi';
  import useAuth from '@/composables/useAuth';
  import type { FlatGatewayRow } from '../types';

  const props = defineProps<{ row: FlatGatewayRow }>();
  const emit = defineEmits<{
    (e: 'success'): void;
    (e: 'cancel'): void;
  }>();

  const { execute } = useApiCall();
  const { routePath } = useAuth();

  const form = reactive({ name: props.row.name || '' });
  const submitting = ref(false);
  const error = ref<string | null>(null);

  async function submit() {
    submitting.value = true;
    error.value = null;

    const url = routePath('gateways_update', { id: props.row.id });
    const result = await execute(
      () => axios.put(url, { gateway: { name: form.name.trim() } }),
      { showSuccessToast: true, successMessage: 'Gateway updated', showErrorToast: false }
    );

    submitting.value = false;
    if (result.success)
      emit('success');
    else
      error.value = result.error.error || 'Could not save gateway.';
  }
</script>
