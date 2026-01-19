<template>
  <CCard>
    <CCardHeader>
      <div class="d-flex justify-content-between align-items-center">
        <div>
          <h5 class="mb-1">Users Management</h5>
          <p class="text-medium-emphasis small mb-0">
            Manage user access and permissions
          </p>
        </div>
        <CButton
          v-if="permissions?.invitations.create"
          color="primary"
          size="sm"
          @click="openInviteModal">
          <CIcon name="cilPlus" class="me-2" />
          Invite User
        </CButton>
      </div>
    </CCardHeader>

    <CCardBody>
      <CTable hover responsive>
        <CTableHead>
          <CTableRow>
            <CTableHeaderCell>User</CTableHeaderCell>
            <CTableHeaderCell>Email</CTableHeaderCell>
            <CTableHeaderCell>Role</CTableHeaderCell>
            <CTableHeaderCell>Sites</CTableHeaderCell>
            <CTableHeaderCell style="width: 100px">Actions</CTableHeaderCell>
          </CTableRow>
        </CTableHead>
        <CTableBody>
          <CTableRow v-for="clientUser in clientUsers" :key="clientUser.id">
            <CTableDataCell>
              <div class="fw-semibold">{{ clientUser.user.name }}</div>
            </CTableDataCell>
            <CTableDataCell>
              <code class="text-medium-emphasis small">{{ clientUser.user.email }}</code>
            </CTableDataCell>
            <CTableDataCell>
              <CBadge :color="getRoleColor(clientUser.role)">
                {{ ROLES[clientUser.role].name }}
              </CBadge>
            </CTableDataCell>
            <CTableDataCell>
              <div class="small text-medium-emphasis">
                {{ getSiteAccessText(clientUser) }}
              </div>
            </CTableDataCell>
            <CTableDataCell>
              <CButtonGroup size="sm">
                <CTooltip
                  v-if="permissions?.client_users.update && canManageUser(clientUser) && clientUser.user_id !== user?.id"
                  content="Change role">
                  <template #toggler="{ id, on }">
                    <CButton
                      v-on="on"
                      color="light"
                      @click="openChangeRoleModal(clientUser)">
                      <CIcon name="cilPencil" />
                    </CButton>
                  </template>
                </CTooltip>
                <CTooltip
                  v-if="(permissions?.client_users.destroy && canManageUser(clientUser)) || clientUser.user_id === user?.id"
                  :content="clientUser.user_id === user?.id ? 'Leave Company' : 'Delete user'">
                  <template #toggler="{ id, on }">
                    <CButton
                      v-if="clientUser.user_id === user?.id"
                      v-on="on"
                      color="light"
                      @click="openDeleteUserModal(clientUser)">
                      <CIcon name="cilRunning" />
                    </CButton>
                    <CButton
                      v-else
                      v-on="on"
                      color="light"
                      @click="openDeleteUserModal(clientUser)">
                      <CIcon name="cilTrash" />
                    </CButton>
                  </template>
                </CTooltip>
              </CButtonGroup>
            </CTableDataCell>
          </CTableRow>

          <CTableRow v-for="invitation in invitations" :key="invitation.id">
            <CTableDataCell></CTableDataCell>
            <CTableDataCell>
              <code class="text-medium-emphasis small">{{ invitation.email }}</code>
            </CTableDataCell>
            <CTableDataCell>
              <CBadge :color="getRoleColor(invitation.role)">
                {{ ROLES[invitation.role].name }}
              </CBadge>
              ({{ invitation.expired ? 'Expired' : 'Pending' }} invitation)
            </CTableDataCell>
            <CTableDataCell>
              <div class="small text-medium-emphasis">
                {{ getSiteAccessText(invitation) }}
              </div>
            </CTableDataCell>
            <CTableDataCell>
              <CButtonGroup size="sm">
                <CTooltip
                  v-if="permissions?.invitations.resend && !invitation.expired"
                  content="Resend invitation">
                  <template #toggler="{ id, on }">
                    <CButton
                      v-on="on"
                      color="light"
                      @click="resendInvitation(invitation)">
                      <CIcon name="cilEnvelopeClosed" />
                    </CButton>
                  </template>
                </CTooltip>
                <CTooltip
                  v-if="permissions?.invitations.destroy"
                  content="Cancel invitation">
                  <template #toggler="{ id, on }">
                  <CButton
                    v-on="on"
                    color="light"
                    @click="openDeleteInvitationModal(invitation)">
                    <CIcon name="cilTrash" />
                  </CButton>
                  </template>
                </CTooltip>
              </CButtonGroup>
            </CTableDataCell>
          </CTableRow>
        </CTableBody>
      </CTable>
    </CCardBody>

    <!-- Invite User Modal -->
    <InviteUserModal
      :visible="showInviteModal"
      @close="closeInviteModal"
      @invite="handleInvite" />

    <!-- Change Role Modal -->
    <ChangeRoleModal
      :visible="showChangeRoleModal"
      :clientUser="editingClientUser"
      @close="closeChangeRoleModal"
      @update="handleRoleUpdated" />

    <!-- Delete User Confirmation Modal -->
    <CModal
      :visible="showDeleteModal"
      @close="closeDeleteUserModal">
      <CModalHeader>
        <CModalTitle>Delete User</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <p v-if="clientUserToDelete?.user_id === user?.id">
          Leave the company?
        </p>
        <p v-else>
          Delete <strong>{{ clientUserToDelete?.user.name }}</strong> from your organization?
        </p>
        <CAlert color="danger" class="d-flex align-items-center mb-0">
          <CIcon name="cilWarning" class="me-2" />
          <div>This will revoke all access and cannot be undone.</div>
        </CAlert>
      </CModalBody>
      <CModalFooter>
        <CButton
          color="secondary"
          @click="closeDeleteUserModal">
          Cancel
        </CButton>
        <CButton
          color="danger"
          :disabled="isDeletingClientUser"
          @click="handleDeleteClientUser">
          <CSpinner v-if="isDeletingClientUser" size="sm" class="me-2" />
          {{ isDeletingClientUser ? 'Deleting...' : 'Delete User' }}
        </CButton>
      </CModalFooter>
    </CModal>

    <!-- Delete Invitation Confirmation Modal -->
    <CModal
      :visible="showDeleteInvitationModal"
      @close="closeDeleteInvitationModal">
      <CModalHeader>
        <CModalTitle>Cancel Invitation</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <p>
          Cancel invitation for <strong>{{ invitationToDelete?.email }}</strong>?
        </p>
        <p class="text-medium-emphasis mb-0 small">
          They will not be able to accept this invitation.
        </p>
      </CModalBody>
      <CModalFooter>
        <CButton
          color="secondary"
          @click="closeDeleteInvitationModal">
          Cancel
        </CButton>
        <CButton
          color="danger"
          :disabled="isDeletingInvitation"
          @click="handleDeleteInvitation">
          <CSpinner v-if="isDeletingInvitation" size="sm" class="me-2" />
          {{ isDeletingInvitation ? 'Canceling...' : 'Cancel Invitation' }}
        </CButton>
      </CModalFooter>
    </CModal>
  </CCard>
</template>

<script lang="ts" setup>
  import { ref, onMounted } from 'vue';
  import axios from 'axios';
  import useAuth from '@/composables/useAuth';
  import usePermissions from '@/composables/usePermissions';
  import { useApiCall } from '@/composables/useApi';
  import { ROLES, type Role, ROUTES } from '@/types/permissions';
  import InviteUserModal from '../modals/InviteUserModal.vue';
  import ChangeRoleModal from '../modals/ChangeRoleModal.vue';
  import type { Site } from '@/types/location';
  import type { ClientUser, Invitation } from '../types/invitation';

  const { user, role } = useAuth();
  const { permissions } = usePermissions();
  const { execute } = useApiCall();

  const clientUsers = ref<ClientUser[]>([]);
  const invitations = ref<Invitation[]>([]);

  const showInviteModal = ref(false);

  const showChangeRoleModal = ref(false);
  const editingClientUser = ref<ClientUser | null>(null);

  const showDeleteModal = ref(false);
  const clientUserToDelete = ref<ClientUser | null>(null);
  const isDeletingClientUser = ref(false);

  const showDeleteInvitationModal = ref(false);
  const invitationToDelete = ref<Invitation | null>(null);
  const isDeletingInvitation = ref(false);

  function openInviteModal() {
    showInviteModal.value = true;
  }

  function closeInviteModal() {
    showInviteModal.value = false;
  }

  function canManageUser(clientUser: ClientUser) {
    if (!role.value)
      return false;

    const currentLevel = ROLES[role.value].level;
    const userLevel = ROLES[clientUser.role].level;

    return currentLevel >= userLevel;
  }

  function getSiteAccessText(userable: { role: Role; site_ids?: Site['id'][] }): string {
    const clientUserRole = userable.role;

    if (!ROLES[clientUserRole].siteSpecific)
      return 'All sites';

    if (!userable.site_ids)
      return '—';

    const count = userable.site_ids?.length;
    if (count === 0)
      return 'No sites';
    if (count === 1)
      return '1 site';
    return `${count} sites`;
  }

  function getRoleColor(role: Role) {
    const colors: Record<Role, string> = {
      admin: 'danger',
      site_admin: 'primary',
      manager: 'warning',
      viewer: 'info'
    };
    return colors[role];
  }

  function openChangeRoleModal(clientUser: ClientUser) {
    editingClientUser.value = clientUser;
    showChangeRoleModal.value = true;
  }

  function closeChangeRoleModal() {
    showChangeRoleModal.value = false;
    editingClientUser.value = null;
  }

  function openDeleteUserModal(clientUser: ClientUser) {
    clientUserToDelete.value = clientUser;
    showDeleteModal.value = true;
  }

  function closeDeleteUserModal() {
    showDeleteModal.value = false;
    clientUserToDelete.value = null;
  }

  function openDeleteInvitationModal(invitation: Invitation) {
    invitationToDelete.value = invitation;
    showDeleteInvitationModal.value = true;
  }

  function closeDeleteInvitationModal() {
    showDeleteInvitationModal.value = false;
    invitationToDelete.value = null;
  }

  async function handleRoleUpdated(updatedClientUser: ClientUser) {
    const clientUserUpdated = clientUsers.value.find((u) => u.id === updatedClientUser.id);
    if (clientUserUpdated) {
      clientUserUpdated.role = updatedClientUser.role;
      clientUserUpdated.site_ids = updatedClientUser.site_ids;
    }

    closeChangeRoleModal();
  }

  async function handleDeleteClientUser() {
    if (!clientUserToDelete.value)
      return;

    isDeletingClientUser.value = true;

    const url = ROUTES.client_users_destroy.path.replace(':id', String(clientUserToDelete.value.id));
    const { success } = await execute(
      () => axios.delete(url),
      {
        showSuccessToast: true,
        successMessage: 'User deleted successfully',
        showErrorToast: true,
        errorTitle: 'Delete Error'
      }
    );

    if (success) {
      const index = clientUsers.value.findIndex((u) => u.id === clientUserToDelete.value!.id);
      if (index > -1)
        clientUsers.value.splice(index, 1);

      closeDeleteUserModal();
    }

    isDeletingClientUser.value = false;
  }

  async function handleInvite(invitation: Invitation) {
    invitations.value.push(invitation);
    closeInviteModal();
  }

  async function resendInvitation(invitation: Invitation) {
    const url = ROUTES.invitations_resend.path.replace(':id', String(invitation.id));
    await execute(
      () => axios.put(url),
      {
        showSuccessToast: true,
        successMessage: 'Invitation resent successfully',
        showErrorToast: true,
        errorTitle: 'Resend Error'
      }
    );
  }

  async function handleDeleteInvitation() {
    if (!invitationToDelete.value)
      return;

    isDeletingInvitation.value = true;

    const url = ROUTES.invitations_destroy.path.replace(':id', String(invitationToDelete.value.id));
    const { success } = await execute(
      () => axios.delete(url),
      {
        showSuccessToast: true,
        successMessage: 'Invitation canceled successfully',
        showErrorToast: true,
        errorTitle: 'Delete Error'
      }
    );

    if (success) {
      const index = invitations.value.findIndex((i) => i.id === invitationToDelete.value!.id);
      if (index > -1)
        invitations.value.splice(index, 1);

      closeDeleteInvitationModal();
    }

    isDeletingInvitation.value = false;
  }

  async function loadData() {
    await Promise.all([
      loadClientUsers(),
      loadInvitations()
    ]);
  }

  async function loadClientUsers() {
    const { success, data } = await execute<ClientUser[]>(
      () => axios.get(ROUTES.client_users_index.path),
      { errorTitle: 'Load Users Error',   showErrorToast: true }
    );

    if (success)
      clientUsers.value = data;
  }

  async function loadInvitations() {
    if (!permissions.value?.invitations.index)
      return;

    const { success, data } = await execute<Invitation[]>(
      () => axios.get(ROUTES.invitations_index.path),
      { errorTitle: 'Load Invitations Error', showErrorToast: true }
    );

    if (success)
      invitations.value = data;
  }

  onMounted(() => {
    loadData();
  });
</script>

<style scoped>
  .small {
    font-size: 0.875rem;
  }
</style>
