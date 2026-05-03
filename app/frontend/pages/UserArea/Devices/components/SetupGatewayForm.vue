<template>
  <div>
    <p class="text-muted mb-4">
      This gateway has been delivered to your site but isn't set up yet.
      Give it a name to recognize it on the equipment list.
    </p>

    <div class="bg-light rounded p-3 mb-4 small">
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

    <CForm @submit.prevent="submit">
      <div class="mb-3">
        <CFormLabel>Name <span class="text-danger">*</span></CFormLabel>
        <CFormInput
          v-model="form.name"
          placeholder="e.g. Field gateway A"
          :invalid="!!error"
          required />
        <CFormText>How this gateway will appear in the equipment list.</CFormText>
      </div>

      <div v-if="error" class="alert alert-danger small">{{ error }}</div>

      <div class="d-flex justify-content-end gap-2 mt-4">
        <CButton color="secondary" variant="outline" @click="$emit('cancel')" :disabled="submitting">
          Cancel
        </CButton>
        <CButton color="primary" type="submit" :disabled="submitting || !form.name.trim()">
          <span v-if="submitting" class="spinner-border spinner-border-sm me-2" />
          Set up gateway
        </CButton>
      </div>
    </CForm>
  </div>
</template>

<script lang="ts" setup>
  import { reactive, ref } from 'vue';
  import axios from 'axios';
  import { useApiCall } from '@/composables/useApi';
  import { ROUTES } from '@/types/permissions';
  import type { FlatGatewayRow } from '../types';

  const props = defineProps<{ row: FlatGatewayRow }>();
  const emit = defineEmits<{
    (e: 'success'): void;
    (e: 'cancel'): void;
  }>();

  const { execute } = useApiCall();

  const form = reactive({
    name: props.row.name || '',
  });

  const submitting = ref(false);
  const error = ref<string | null>(null);

  async function submit() {
    if (!form.name.trim())
      return;

    submitting.value = true;
    error.value = null;

    const url = ROUTES.gateways_update.path.replace(':id', String(props.row.id));
    const result = await execute(
      () => axios.put(url, {
        gateway: {
          name: form.name.trim(),
          active: true,
        },
      }),
      {
        showSuccessToast: true,
        successMessage: 'Gateway set up successfully',
        showErrorToast: false,
      }
    );

    submitting.value = false;

    if (result.success) {
      emit('success');
    } else {
      error.value = result.error.error || 'Could not set up gateway. Please try again.';
    }
  }
</script>
