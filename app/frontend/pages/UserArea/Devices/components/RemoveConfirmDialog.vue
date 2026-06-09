<template>
  <div>
    <p>{{ message }}</p>

    <div v-if="row.kind === 'gateway' && childCount > 0" class="alert alert-warning small">
      This gateway has <strong>{{ childCount }}</strong> {{ childWord }} connected.
      Removing it will also un-assign {{ childCount === 1 ? 'it' : 'them' }} from this site.
    </div>

    <div v-if="error" class="alert alert-danger small">{{ error }}</div>

    <div class="d-flex justify-content-end gap-2 mt-4">
      <CButton color="secondary" variant="outline" @click="$emit('cancel')" :disabled="submitting">
        Cancel
      </CButton>
      <CButton color="danger" @click="confirm" :disabled="submitting">
        <span v-if="submitting" class="spinner-border spinner-border-sm me-2" />
        Remove
      </CButton>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed, ref } from 'vue';
  import axios from 'axios';
  import { useApiCall } from '@/composables/useApi';
  import useAuth from '@/composables/useAuth';
  import type { FlatDeviceRow } from '../types';

  const props = defineProps<{ row: FlatDeviceRow }>();
  const emit = defineEmits<{
    (e: 'success'): void;
    (e: 'cancel'): void;
  }>();

  const { execute } = useApiCall();
  const { routePath } = useAuth();

  const submitting = ref(false);
  const error = ref<string | null>(null);

  const childCount = computed(() => props.row.children.length);

  const childWord = computed(() => {
    if (props.row.kind !== 'gateway')
      return '';

    return childCount.value === 1 ? 'controller or device' : 'controllers or devices';
  });

  const message = computed(() => {
    if (props.row.kind === 'gateway')
      return `Remove ${props.row.name || 'this gateway'} from this site?`;

    if (props.row.kind === 'modbus_device')
      return `Remove ${props.row.name || 'this device'}? This will delete the device permanently.`;

    return `Remove ${props.row.name || 'this item'}?`;
  });

  function urlForRow(): string | null {
    // TO FIX: There IS NOT Gattay DESTROY route
    if (props.row.kind === 'gateway')
      return routePath('gateways_destroy', { id: props.row.id });

    if (props.row.kind === 'modbus_device')
      return routePath('modbus_devices_destroy', { id: props.row.id });

    return null;
  }

  async function confirm() {
    const url = urlForRow();
    if (!url) {
      error.value = 'Cannot remove this kind of item.';
      return;
    }

    submitting.value = true;
    error.value = null;

    const result = await execute(
      () => axios.delete(url),
      { showSuccessToast: true, successMessage: 'Removed', showErrorToast: false }
    );

    submitting.value = false;
    if (result.success)
      emit('success');
    else
      error.value = result.error.error || 'Could not remove. Please try again.';
  }
</script>
