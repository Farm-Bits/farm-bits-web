<template>
  <CForm @submit.prevent="handleSubmit">
    <div class="mb-3">
      <CFormLabel class="fw-semibold">Select Terminal</CFormLabel>
      <CFormSelect
        v-model="form.terminal_id"
        :invalid="!!errors.terminal_id"
        @change="handleTerminalSelect">
        <option value="">-- Select a terminal --</option>
        <option
          v-for="terminal in availableTerminals"
          :key="terminal.id"
          :value="terminal.id">
          {{ terminal.label }} ({{ terminal.name }})
        </option>
      </CFormSelect>
      <CFormFeedback v-if="errors.terminal_id" invalid>
        {{ errors.terminal_id }}
      </CFormFeedback>
    </div>

    <!-- Selected Terminal Details Card -->
    <div v-if="selectedTerminalDetails">
      <TerminalDetailsForm
        v-model="form"
        :terminal="selectedTerminalDetails"
        :availablePlcs="availablePlcs" />
    </div>

    <!-- PLC Assignment Section -->
    <div class="pt-3 mb-3">
      <PlcAssignmentManager
        v-model="form.plc_assignments"
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
        Activate Terminal
      </CButton>
    </div>
  </CForm>
</template>

<script lang="ts" setup>
  import { ref, reactive, computed, nextTick } from 'vue';
  import axios from 'axios';
  import TerminalDetailsForm from './TerminalDetailsForm.vue';
  import PlcAssignmentManager from './PlcAssignmentManager.vue';
  import { useApiCall } from '@/composables/useApi';
  import { ROUTES } from '@/types/permissions';
  import type { Terminal, Plc, TerminalAssigned } from '../types';

  const props = defineProps<{
    availableTerminals: Terminal[];
    availablePlcs: Plc[];
  }>();
  const emit = defineEmits<{
    (e: 'cancel'): void;
    (e: 'success', site: TerminalAssigned): void;
  }>();

  const { execute } = useApiCall();

  const form = reactive({
    terminal_id: '',
    customName: '',
    plc_assignments: [] as (Plc & { customName: string })[]
  });

  const errors = ref<Record<string, string>>({});
  const processing = ref(false);

  const selectedTerminalDetails = computed(() => {
    if (!form.terminal_id)
      return null;

    return props.availableTerminals.find((t) => t.id === parseInt(form.terminal_id));
  });

  function handleTerminalSelect() {
    delete errors.value.terminal_id;
    nextTick(() => {
      form.customName = selectedTerminalDetails.value?.name || '';
    });
  }

  async function handleSubmit() {
    processing.value = true;
    errors.value = {};

    const selectedTerminal = props.availableTerminals.find(
      (t) => t.id === parseInt(form.terminal_id)
    );

    if (!selectedTerminal) {
      errors.value.terminal_id = 'Please select a terminal';
      processing.value = false;
      return;
    }

    const submitData = {
      terminal: {
        name: form.customName,
        iccid: selectedTerminal.iccid,
        phone_number: selectedTerminal.phone_number,
        active: true,
        plc_assignments: form.plc_assignments
          .filter((a) => a.id)
          .map((a) => ({ id: a.id, name: a.customName }))
      }
    };

    const url = ROUTES.terminals_update.path.replace(':id', String(selectedTerminal.id));
    const { success, data } = await execute<TerminalAssigned>(
      () => axios.put(url, submitData),
      {
        showSuccessToast: true,
        successMessage: 'Terminal added successfully',
        showErrorToast: true,
        errorTitle: 'Add Terminal Error'
      }
    );

    if (success)
      emit('success', data);

    processing.value = false;
  }
</script>

<style scoped>
</style>
