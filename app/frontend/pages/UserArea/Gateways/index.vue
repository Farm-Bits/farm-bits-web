<template>
  <CContainer fluid class="px-4 py-4">
    <!-- Header -->
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <h1 class="h3 mb-1">Gateways & Controllers</h1>
        <p class="text-muted mb-0">Manage hardware installations for {{ currentSite?.name }}</p>
      </div>
      <CButton
        v-if="permissions?.gateways.update"
        color="primary"
        @click="showActivationModal = true">
        <CIcon icon="cilPlus" class="me-2" />
        Activate Gateway
      </CButton>
    </div>

    <!-- Empty State -->
    <div v-if="gateways.length === 0" class="text-center py-5">
      <CIcon icon="cilRouter" size="4xl" class="text-muted mb-3" />
      <h4 class="text-muted mb-2">No Gateways Installed</h4>
      <p class="text-muted mb-4">Get started by activating your first gateway for this site.</p>
      <CButton
        v-if="permissions?.gateways.update"
        color="primary"
        @click="showActivationModal = true">
        Activate Gateway
      </CButton>
    </div>

    <!-- Gateways List -->
    <CRow v-else class="g-4">
      <CCol v-for="gateway in gateways" :key="gateway.id" class="col-md-3 min-w-sm">
        <CCard class="shadow-sm">
          <CCardHeader class="d-flex justify-content-between bg-white">
            <div class="d-flex align-items-center gap-3">
              <div class="gateway-icon">
                <CIcon icon="cilRouter" size="xl" class="text-primary" />
              </div>
              <div>
                <h5 class="mb-0">{{ gateway.name }}</h5>
                <div class="text-muted small">
                  <span class="me-3">IMEI: {{ gateway.imei }}</span>
                </div>
                <div class="text-muted small">
                  <span v-if="gateway.phone_number">Phone: {{ gateway.phone_number }}</span>
                </div>
              </div>
            </div>
            <div class="d-flex align-items-start gap-2">
              <CBadge class="mt-1" color="success">Active</CBadge>
              <CDropdown class="options-dropdown">
                <CDropdownToggle color="light" size="sm" :caret="false">
                  <CIcon icon="cilOptions" />
                </CDropdownToggle>
                <CDropdownMenu>
                  <CDropdownItem
                    v-if="permissions?.gateways.update"
                    @click="editGateway(gateway)">
                    <CIcon icon="cilPencil" class="me-2" />
                    Edit Gateway
                  </CDropdownItem>
                  <div v-if="permissions?.gateways.destroy">
                    <CDropdownDivider />
                    <CDropdownItem
                      class="text-danger"
                      @click="confirmRemoveGateway(gateway)">
                      <CIcon icon="cilTrash" class="me-2" />
                      Remove Gateway
                    </CDropdownItem>
                  </div>
                </CDropdownMenu>
              </CDropdown>
            </div>
          </CCardHeader>
          <CCardBody class="p-0">
            <!-- Connected PLCs -->
            <div v-if="gateway.plcs && gateway.plcs.length > 0">
              <CTable hover responsive class="mb-0">
                <CTableBody>
                  <CTableRow v-for="plc in gateway.plcs" :key="plc.id" class="align-middle">
                    <CTableDataCell class="text-center">
                      <CIcon icon="cilMemory" class="text-primary" />
                    </CTableDataCell>
                    <CTableDataCell>
                      <Link
                        v-if="permissions?.plcs.show"
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
                v-if="permissions?.gateways.update"
                color="link"
                size="sm"
                @click="editGateway(gateway)">
                Assign Controllers
              </CButton>
            </div>
          </CCardBody>
        </CCard>
      </CCol>
    </CRow>

    <!-- Activation Modal -->
    <CModal
      v-if="permissions?.gateways.update"
      :visible="showActivationModal"
      @close="closeActivationModal"
      size="lg"
      backdrop="static">
      <CModalHeader>
        <CModalTitle>Activate Gateway</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <ActivationForm
          :availableGateways="availableGateways"
          :availablePlcs="availablePlcs"
          @success="handleActivationSuccess"
          @cancel="closeActivationModal" />
      </CModalBody>
    </CModal>

    <!-- Edit Modal -->
    <CModal
      v-if="permissions?.gateways.update"
      :visible="showEditModal"
      @close="closeEditModal"
      size="lg"
      backdrop="static">
      <CModalHeader>
        <CModalTitle>Edit Gateway</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <GatewayEditForm
          v-if="selectedGateway"
          :gateway="selectedGateway"
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
        <p>Are you sure you want to remove this gateway from {{ currentSite?.name }}?</p>
        <div v-if="gatewayToRemove" class="alert alert-warning">
          <strong>Gateway:</strong> {{ gatewayToRemove.name }}<br>
          <strong>IMEI:</strong> {{ gatewayToRemove.imei }}<br>
          <strong>Controllers Connected:</strong> {{ getPlcCount(gatewayToRemove) }}
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
        <CButton color="danger" @click="removeGateway">
          Remove Gateway
        </CButton>
      </CModalFooter>
    </CModal>
  </CContainer>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import axios from 'axios';
  import ActivationForm from './components/ActivationForm.vue';
  import GatewayEditForm from './components/EditForm.vue';
  import useAuth from '@/composables/useAuth';
  import usePermissions from '@/composables/usePermissions';
  import { useApiCall } from '@/composables/useApi';
  import { ROUTES } from '@/types/permissions';
  import type { Gateway, GatewayAssigned } from '@/types/gateway';
  import type { Plc } from '@/types/plc';

  const { permissions } = usePermissions();
  const { execute } = useApiCall();

  const { currentSite, pageProps } = useAuth<{
    gateways: GatewayAssigned[];
    availableGateways: Gateway[];
    availablePlcs: Plc[];
  }>();
  const { gateways, availableGateways, availablePlcs } = pageProps.value;

  const showActivationModal = ref(false);
  const showEditModal = ref(false);
  const showConfirmModal = ref(false);
  const selectedGateway = ref<GatewayAssigned | null>(null);
  const gatewayToRemove = ref<GatewayAssigned | null>(null);

  function getPlcCount(gateway: GatewayAssigned): number {
    return gateway.plcs?.length || 0;
  }

  function editGateway(gateway: GatewayAssigned) {
    selectedGateway.value = gateway;
    showEditModal.value = true;
  }

  function confirmRemoveGateway(gateway: GatewayAssigned) {
    gatewayToRemove.value = gateway;
    showConfirmModal.value = true;
  }

  async function removeGateway() {
    if (!gatewayToRemove.value)
      return;

    const url = ROUTES.gateways_destroy.path.replace(':id', String(gatewayToRemove.value.id));
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
      const index = gateways.findIndex((t) => t.id === gatewayToRemove.value!.id);
      if (index > -1) {
        const plcsToRemove = gateways[index].plcs;
        plcsToRemove.forEach((plc) => {
          availablePlcs.push(plc);
        });
        gateways.splice(index, 1);
      }

      gatewayToRemove.value.plcs = [];
      availableGateways.push(gatewayToRemove.value);

      closeConfirmModal();
    }
  }

  function closeActivationModal() {
    showActivationModal.value = false;
  }

  function closeEditModal() {
    showEditModal.value = false;
    selectedGateway.value = null;
  }

  function closeConfirmModal() {
    showConfirmModal.value = false;
    gatewayToRemove.value = null;
  }

  function handleActivationSuccess(gateway: GatewayAssigned) {
    const index = availableGateways.findIndex((t) => t.id === gateway.id);
    if (index > -1)
      availableGateways.splice(index, 1);

    gateway.plcs.forEach((plc) => {
      const plcWasAvailableIndex = availablePlcs.findIndex((p) => p.id === plc.id);
      if (plcWasAvailableIndex > -1)
        availablePlcs.splice(plcWasAvailableIndex, 1);
    });

    gateways.push(gateway);

    closeActivationModal();
  }

  function handleEditSuccess(oldGateway: GatewayAssigned, newGateway: GatewayAssigned) {
    const index = gateways.findIndex((t) => t.id === newGateway.id);
    if (index !== -1)
      gateways.splice(index, 1, newGateway);

    newGateway.plcs.forEach((plc) => {
      const plcWasAvailableIndex = availablePlcs.findIndex((p) => p.id === plc.id);
      if (plcWasAvailableIndex !== -1)
        availablePlcs.splice(plcWasAvailableIndex, 1);
    });

    oldGateway.plcs.forEach((plc) => {
      const plcIsStillAssigned = newGateway.plcs.some((p) => p.id === plc.id);
      if (!plcIsStillAssigned)
        availablePlcs.push(plc);
    });

    closeEditModal();
  }
</script>

<style scoped>
  .gateway-icon {
    width: 48px;
    height: 48px;
    border-radius: 12px;
    background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
    display: flex;
    align-items: center;
    justify-content: center;
  }
</style>
