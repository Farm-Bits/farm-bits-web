<template>
  <div class="container-fluid px-4 py-4">
    <!-- Header -->
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <h1 class="h3 mb-1">Gateways & Controllers</h1>
        <p class="text-muted mb-0">Manage hardware installations for {{ site?.name }}</p>
      </div>
      <CButton
        v-if="permissions.terminals.update"
        color="primary"
        @click="showActivationModal = true">
        <CIcon icon="cilPlus" class="me-2" />
        Activate Gateway
      </CButton>
    </div>

    <!-- Empty State -->
    <div v-if="terminals.length === 0" class="text-center py-5">
      <CIcon icon="cilRouter" size="4xl" class="text-muted mb-3" />
      <h4 class="text-muted mb-2">No Gateways Installed</h4>
      <p class="text-muted mb-4">Get started by activating your first gateway for this site.</p>
      <CButton
        v-if="permissions.terminals.update"
        color="primary"
        @click="showActivationModal = true">
        Activate Gateway
      </CButton>
    </div>

    <!-- Terminals List -->
    <div v-else class="row g-4">
      <div v-for="terminal in terminals" :key="terminal.id" class="col-md-3 min-w-sm">
        <CCard class="shadow-sm">
          <CCardHeader class="d-flex justify-content-between bg-white">
            <div class="d-flex align-items-center gap-3">
              <div class="terminal-icon">
                <CIcon icon="cilRouter" size="xl" class="text-primary" />
              </div>
              <div>
                <h5 class="mb-0">{{ terminal.name }}</h5>
                <div class="text-muted small">
                  <span class="me-3">IMEI: {{ terminal.imei }}</span>
                </div>
                <div class="text-muted small">
                  <span v-if="terminal.phone_number">Phone: {{ terminal.phone_number }}</span>
                </div>
              </div>
            </div>
            <div class="d-flex align-items-start gap-2">
              <CBadge class="mt-1" color="success">Active</CBadge>
              <CDropdown>
                <CDropdownToggle color="light" size="sm" :caret="false">
                  <CIcon icon="cilOptions" />
                </CDropdownToggle>
                <CDropdownMenu>
                  <CDropdownItem
                    v-if="permissions.terminals.update"
                    @click="editTerminal(terminal)">
                    <CIcon icon="cilPencil" class="me-2" />
                    Edit Gateway
                  </CDropdownItem>
                  <CDropdownDivider v-if="permissions.terminals.destroy" />
                  <CDropdownItem
                    v-if="permissions.terminals.destroy"
                    class="text-danger"
                    @click="confirmRemoveTerminal(terminal)">
                    <CIcon icon="cilTrash" class="me-2" />
                    Remove Gateway
                  </CDropdownItem>
                </CDropdownMenu>
              </CDropdown>
            </div>
          </CCardHeader>
          <CCardBody class="p-0">
            <!-- Connected PLCs -->
            <div v-if="terminal.plcs && terminal.plcs.length > 0">
              <CTable hover responsive class="mb-0">
                <CTableBody>
                  <CTableRow v-for="plc in terminal.plcs" :key="plc.id" class="align-middle">
                    <CTableDataCell class="text-center">
                      <CIcon icon="cilMemory" class="text-primary" />
                    </CTableDataCell>
                    <CTableDataCell>
                      <Link
                        v-if="permissions.plcs.show"
                        class="nav-link nav-link-secondary"
                        :href="ROUTES.plcs_show.path.replace(':id', String(plc.id))">
                        {{ plc.name }}
                      </Link>
                      <span v-else>{{ plc.name }}</span>
                      <div class="text-muted small">{{ plc.label }}</div>
                    </CTableDataCell>
                    <CTableDataCell class="text-center">
                      <CBadge color="info">{{ plc.plc_version.name }}</CBadge>
                    </CTableDataCell>
                    <CTableDataCell class="text-center">
                      <CBadge color="success">
                        <CIcon icon="cilCheckCircle" size="sm" class="me-1" />
                        Connected
                      </CBadge>
                    </CTableDataCell>
                  </CTableRow>
                </CTableBody>
              </CTable>
            </div>
            <div v-else class="text-center py-4 text-muted">
              <CIcon icon="cilPlug" size="xl" class="mb-2" />
              <div>No controllers connected to this gateway</div>
              <CButton
                v-if="permissions.terminals.update"
                color="link"
                size="sm"
                @click="editTerminal(terminal)">
                Assign Controllers
              </CButton>
            </div>
          </CCardBody>
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
        <CModalTitle>Activate Gateway</CModalTitle>
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
        <CModalTitle>Edit Gateway</CModalTitle>
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
        <p>Are you sure you want to remove this gateway from {{ site?.name }}?</p>
        <div v-if="terminalToRemove" class="alert alert-warning">
          <strong>Gateway:</strong> {{ terminalToRemove.name }}<br>
          <strong>IMEI:</strong> {{ terminalToRemove.imei }}<br>
          <strong>Controllers Connected:</strong> {{ getPlcCount(terminalToRemove) }}
        </div>
        <p class="small text-muted">
          This will unassign the gateway and all connected controllers from this site.
          The hardware can be reassigned to another site later.
        </p>
      </CModalBody>
      <CModalFooter>
        <CButton color="secondary" @click="closeConfirmModal">
          Cancel
        </CButton>
        <CButton color="danger" @click="removeTerminal">
          Remove Gateway
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
  import type { Terminal, TerminalAssigned } from '@/types/terminal';
  import type { Plc } from '@/types/plc';

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
        successMessage: 'Gateway removed successfully',
        showErrorToast: true,
        errorTitle: 'Remove Gateway Error'
      }
    );

    if (success) {
      const index = terminals.findIndex((t) => t.id === terminalToRemove.value!.id);
      if (index > -1) {
        const plcsToRemove = terminals[index].plcs;
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
  .terminal-icon {
    width: 48px;
    height: 48px;
    border-radius: 12px;
    background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
    display: flex;
    align-items: center;
    justify-content: center;
  }
</style>
