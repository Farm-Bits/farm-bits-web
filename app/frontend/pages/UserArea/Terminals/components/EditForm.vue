<template>
  <CForm @submit.prevent="handleSubmit">
    <!-- Terminal Details -->
    <TerminalDetailsForm
      v-model="formData"
      :terminal="terminal"
      :availablePlcs="localAvailablePlcs" />

    <!-- PLC Assignment Section -->
    <div class="pt-3 mb-3">
      <PlcAssignmentManager
        v-model="formData.plc_assignments"
        :availablePlcs="localAvailablePlcs" />
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
        Update Terminal
      </CButton>
    </div>
  </CForm>
</template>

<script lang="ts" setup>
  import { ref, reactive, onMounted } from 'vue';
  import axios from 'axios';
  import TerminalDetailsForm from './TerminalDetailsForm.vue';
  import PlcAssignmentManager from './PlcAssignmentManager.vue';
  import { useApiCall } from '@/composables/useApi';
  import { ROUTES } from '@/types/permissions';
  import type { TerminalAssigned } from '@/types/terminal';
  import type { Plc } from '@/types/plc';

  const props = defineProps<{
    terminal: TerminalAssigned;
    availablePlcs: Plc[];
  }>();
  const emit = defineEmits<{
    (e: 'cancel'): void;
    (e: 'success', oldTerminal: TerminalAssigned, newTerminal: TerminalAssigned): void;
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
    formData.customName = props.terminal.name || '';

    if (props.terminal.plcs) {
      formData.plc_assignments = props.terminal.plcs.map((plc) => ({
        ...plc,
        customName: plc.name
      }));
    }

    localAvailablePlcs.value = [
      ...props.availablePlcs,
      ...props.terminal.plcs
    ];
  });

  async function handleSubmit() {
    processing.value = true;
    errors.value = {};

    const submitData = {
      terminal: {
        name: formData.customName,
        plc_assignments: formData.plc_assignments
          .filter((a) => a.id)
          .map((a) => ({ id: a.id, name: a.customName }))
      }
    };

    const url = ROUTES.terminals_update.path.replace(':id', String(props.terminal.id));
    const { success, data } = await execute<TerminalAssigned>(
      () => axios.put(url, submitData),
      {
        showSuccessToast: true,
        successMessage: 'Terminal updated successfully',
        showErrorToast: true,
        errorTitle: 'Update Terminal Error'
      }
    );

    if (success)
      emit('success', props.terminal, data);

    processing.value = false;
  }
</script>

<style scoped>
</style>
