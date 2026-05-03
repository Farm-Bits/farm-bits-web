<template>
  <CForm @submit.prevent="submit">
    <div class="mb-3">
      <CFormLabel>Name <span class="text-danger">*</span></CFormLabel>
      <CFormInput v-model="form.name" required />
    </div>

    <div class="mb-3">
      <CFormLabel>Modbus address (1–247) <span class="text-danger">*</span></CFormLabel>
      <CFormInput
        type="number"
        v-model.number="form.slave_id"
        min="1"
        max="247"
        required />
    </div>

    <div v-if="row.details.host_kind === 'gateway'" class="mb-3">
      <CFormLabel>IP address <span class="text-danger">*</span></CFormLabel>
      <CFormInput v-model="form.private_ip" required />
    </div>

    <div class="mb-3">
      <CFormCheck
        v-model="form.active"
        :checked="form.active"
        @change="form.active = ($event.target as HTMLInputElement).checked"
        id="modbus_device_active"
        label="Polling enabled" />
      <CFormText>When disabled, this device will not be polled or written to.</CFormText>
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
          <span class="text-muted">Connection:</span>
          <strong class="ms-1">
            {{ row.details.host_kind === 'gateway' ? 'Gateway (direct)' : 'Controller (bridged)' }}
          </strong>
        </div>
        <div v-if="row.details.host_kind === 'plc'" class="col-6">
          <span class="text-muted">Slot:</span>
          <strong class="ms-1">{{ row.details.slot_number }}</strong>
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
  import type { FlatModbusDeviceRow } from '../types';

  const props = defineProps<{ row: FlatModbusDeviceRow }>();
  const emit = defineEmits<{
    (e: 'success'): void;
    (e: 'cancel'): void;
  }>();

  const { execute } = useApiCall();

  const form = reactive<{
    name: string;
    slave_id: number;
    private_ip: string;
    active: boolean;
  }>({
    name: props.row.name || '',
    slave_id: props.row.details.slave_id,
    private_ip: props.row.details.private_ip || '',
    active: props.row.active,
  });

  const submitting = ref(false);
  const error = ref<string | null>(null);

  const canSubmit = computed(() => {
    if (!form.name.trim()) return false;
    if (form.slave_id < 1 || form.slave_id > 247) return false;
    if (props.row.details.host_kind === 'gateway' && !form.private_ip.trim()) return false;
    return true;
  });

  async function submit() {
    if (!canSubmit.value)
      return;

    submitting.value = true;
    error.value = null;

    const payload: Record<string, unknown> = {
      name: form.name.trim(),
      slave_id: form.slave_id,
      active: form.active,
    };
    if (props.row.details.host_kind === 'gateway') {
      payload.private_ip = form.private_ip.trim();
    }

    const url = ROUTES.modbus_devices_update.path.replace(':id', String(props.row.id));
    const result = await execute(
      () => axios.put(url, { modbus_device: payload }),
      { showSuccessToast: true, successMessage: 'Device updated', showErrorToast: false }
    );

    submitting.value = false;
    if (result.success) {
      emit('success');
    } else {
      error.value = result.error.error || 'Could not save device.';
    }
  }
</script>
