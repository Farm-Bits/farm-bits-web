<template>
  <div class="container-fluid px-4 py-4">
    <!-- Header -->
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <h1 class="h3 mb-1">Terminals & PLCs</h1>
        <p class="text-muted mb-0">Manage hardware installations for {{ site?.name }}</p>
      </div>
      <CButton
        v-if="permissions.terminals.update"
        color="primary"
        @click="showActivationModal = true">
        <CIcon icon="cilPlus" class="me-2" />
        Activate Terminal
      </CButton>
    </div>

    <!-- Empty State -->
    <div v-if="terminals.length === 0" class="text-center py-5">
      <CIcon icon="cilRouter" size="4xl" class="text-muted mb-3" />
      <h4 class="text-muted mb-2">No Terminals Installed</h4>
      <p class="text-muted mb-4">Get started by activating your first terminal for this site.</p>
      <CButton
        v-if="permissions.terminals.update"
        color="primary"
        @click="showActivationModal = true">
        Activate Terminal
      </CButton>
    </div>

    <!-- Terminals List -->
    <div v-else class="row g-4">
      <div v-for="terminal in terminals" :key="terminal.id" class="col-md-6 col-lg-4">
        <CCard class="h-100 shadow-sm hover-shadow">
          <CCardHeader class="d-flex justify-content-between align-items-center">
            <div class="d-flex align-items-center">
              <CIcon icon="cilRouter" size="lg" class="text-primary me-2" />
              <strong>{{ terminal.name }}</strong>
            </div>
            <CBadge color="success">Active</CBadge>
          </CCardHeader>
          <CCardBody>
            <!-- Terminal Details -->
            <div class="mb-3">
              <div class="d-flex justify-content-between mb-2">
                <span class="text-muted small">IMEI:</span>
                <span class="small font-monospace">{{ terminal.imei }}</span>
              </div>
              <div class="d-flex justify-content-between mb-2">
                <span class="text-muted small">ICCID:</span>
                <span class="small font-monospace">{{ terminal.iccid }}</span>
              </div>
              <div class="d-flex justify-content-between mb-2">
                <span class="text-muted small">Phone:</span>
                <span class="small">{{ terminal.phone_number }}</span>
              </div>
              <!-- <div class="d-flex justify-content-between mb-2">
                <span class="text-muted small">Model:</span>
                <span class="small">{{ terminal.model?.name || 'N/A' }}</span>
              </div> -->
            </div>

            <!-- Connected PLCs -->
            <div class="border-top pt-3">
              <div class="d-flex justify-content-between align-items-center mb-2">
                <span class="text-muted small">Connected PLCs:</span>
                <CBadge color="info">{{ getPlcCount(terminal) }}</CBadge>
              </div>
              <div v-if="terminal.plcs && terminal.plcs.length > 0" class="small">
                <div
                  v-for="plc in terminal.plcs"
                  :key="plc.id"
                  class="d-flex justify-content-between py-1 border-bottom">
                  <span>
                    <CBadge color="success">Active</CBadge>
                    <Link class="nav-link nav-link-secondary d-inline-block ms-2" :href="`/user/plcs/${plc.id}`">
                      {{ plc.name }}
                    </Link>
                  </span>
                  <span class="text-muted">Slave: {{ plc.slave }}</span>
                </div>
              </div>
              <div v-else class="small text-muted">
                No PLCs Connected
              </div>
            </div>
          </CCardBody>
          <CCardFooter class="d-flex justify-content-end gap-2">
            <CButton
              v-if="permissions.terminals.update"
              color="light"
              size="sm"
              @click="editTerminal(terminal)">
              <CIcon icon="cilPencil" class="me-1" />
              Edit
            </CButton>
            <CButton
              v-if="permissions.terminals.destroy"
              color="danger"
              size="sm"
              variant="outline"
              @click="confirmRemoveTerminal(terminal)">
              <CIcon icon="cilTrash" class="me-1" />
              Remove
            </CButton>
          </CCardFooter>
        </CCard>
      </div>
    </div>

    <!-- Activation Modal -->
    <CModal
      v-if="permissions.terminals.update"
      :visible="showActivationModal"
      @close="closeActivationModal"
      size="lg"
      backdrop="static">
      <CModalHeader>
        <CModalTitle>Activate Terminal</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <ActivationForm
          :availableTerminals="availableTerminals"
          :availablePlcs="availablePlcs"
          @success="handleActivationSuccess"
          @cancel="closeActivationModal" />
      </CModalBody>
    </CModal>

    <!-- Edit Modal -->
    <CModal
      v-if="permissions.terminals.update"
      :visible="showEditModal"
      @close="closeEditModal"
      size="lg"
      backdrop="static">
      <CModalHeader>
        <CModalTitle>Edit Terminal</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <TerminalEditForm
          v-if="selectedTerminal"
          :terminal="selectedTerminal"
          :availablePlcs="availablePlcs"
          @success="handleEditSuccess"
          @cancel="closeEditModal" />
      </CModalBody>
    </CModal>

    <!-- Confirmation Modal -->
    <CModal
      :visible="showConfirmModal"
      @close="closeConfirmModal"
      backdrop="static">
      <CModalHeader>
        <CModalTitle>Confirm Removal</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <p>Are you sure you want to remove this terminal from {{ site?.name }}?</p>
        <div v-if="terminalToRemove" class="alert alert-warning">
          <strong>Terminal:</strong> {{ terminalToRemove.imei }}<br>
          <strong>PLCs Connected:</strong> {{ getPlcCount(terminalToRemove) }}
        </div>
        <p class="small text-muted">
          This will unassign the terminal and all connected PLCs from this site.
          The hardware can be reassigned to another site later.
        </p>
      </CModalBody>
      <CModalFooter>
        <CButton color="secondary" @click="closeConfirmModal">
          Cancel
        </CButton>
        <CButton color="danger" @click="removeTerminal">
          Remove Terminal
        </CButton>
      </CModalFooter>
    </CModal>
  </div>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import axios from 'axios';
  import ActivationForm from './components/ActivationForm.vue';
  import TerminalEditForm from './components/EditForm.vue';
  import useAuth from '@/composables/useAuth';
  import usePermissions from '@/composables/usePermissions';
  import { useApiCall } from '@/composables/useApi';
  import { ROUTES } from '@/types/permissions';
  import type { Terminal, TerminalAssigned, Plc } from './types';

  const { permissions } = usePermissions();
  const { execute } = useApiCall();

  const { site, pageProps } = useAuth<{
    terminals: TerminalAssigned[];
    availableTerminals: Terminal[];
    availablePlcs: Plc[];
  }>();
  const { terminals, availableTerminals, availablePlcs } = pageProps.value;

  const showActivationModal = ref(false);
  const showEditModal = ref(false);
  const showConfirmModal = ref(false);
  const selectedTerminal = ref<TerminalAssigned | null>(null);
  const terminalToRemove = ref<TerminalAssigned | null>(null);

  function getPlcCount(terminal: TerminalAssigned): number {
    return terminal.plcs?.length || 0;
  }

  function editTerminal(terminal: TerminalAssigned) {
    selectedTerminal.value = terminal;
    showEditModal.value = true;
  }

  function confirmRemoveTerminal(terminal: TerminalAssigned) {
    terminalToRemove.value = terminal;
    showConfirmModal.value = true;
  }

  async function removeTerminal() {
    if (!terminalToRemove.value)
      return;

    const url = ROUTES.terminals_destroy.path.replace(':id', String(terminalToRemove.value.id));
    const { success } = await execute(
      () => axios.delete(url),
      {
        showSuccessToast: true,
        successMessage: 'Terminal removed successfully',
        showErrorToast: true,
        errorTitle: 'Remove Terminal Error'
      }
    );

    if (success) {
      const index = terminals.findIndex((t) => t.id === terminalToRemove.value!.id);
      if (index > -1) {
        const plcsToRemove = terminals[index].plcs;;
        plcsToRemove.forEach((plc) => {
          availablePlcs.push(plc);
        });
        terminals.splice(index, 1);
      }

      terminalToRemove.value.plcs = [];
      availableTerminals.push(terminalToRemove.value);

      closeConfirmModal();
    }
  }

  function closeActivationModal() {
    showActivationModal.value = false;
  }

  function closeEditModal() {
    showEditModal.value = false;
    selectedTerminal.value = null;
  }

  function closeConfirmModal() {
    showConfirmModal.value = false;
    terminalToRemove.value = null;
  }

  function handleActivationSuccess(terminal: TerminalAssigned) {
    const index = availableTerminals.findIndex((t) => t.id === terminal.id);
    if (index > -1)
      availableTerminals.splice(index, 1);

    terminal.plcs.forEach((plc) => {
      const plcWasAvailableIndex = availablePlcs.findIndex((p) => p.id === plc.id);
      if (plcWasAvailableIndex > -1)
        availablePlcs.splice(plcWasAvailableIndex, 1);
    });

    terminals.push(terminal);

    closeActivationModal();
  }

  function handleEditSuccess(oldTerminal: TerminalAssigned, newTerminal: TerminalAssigned) {
    const index = terminals.findIndex((t) => t.id === newTerminal.id);
    if (index !== -1)
      terminals.splice(index, 1, newTerminal);

    newTerminal.plcs.forEach((plc) => {
      const plcWasAvailableIndex = availablePlcs.findIndex((p) => p.id === plc.id);
      if (plcWasAvailableIndex !== -1)
        availablePlcs.splice(plcWasAvailableIndex, 1);
    });

    oldTerminal.plcs.forEach((plc) => {
      const plcIsStillAssigned = newTerminal.plcs.some((p) => p.id === plc.id);
      if (!plcIsStillAssigned)
        availablePlcs.push(plc);
    });

    closeEditModal();
  }
</script>

<style scoped>
.hover-shadow {
    transition: box-shadow 0.2s ease-in-out;
  }

  .hover-shadow:hover {
    box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15) !important;
  }
</style>