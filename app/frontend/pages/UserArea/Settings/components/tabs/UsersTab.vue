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
            <CTableHeaderCell>Site Access</CTableHeaderCell>
            <CTableHeaderCell style="width: 100px">Actions</CTableHeaderCell>
          </CTableRow>
        </CTableHead>
        <CTableBody>
          <CTableRow v-for="companyUser in companyUsers" :key="companyUser.id">
            <CTableDataCell>
              <div class="fw-semibold">{{ companyUser.user.name }}</div>
            </CTableDataCell>
            <CTableDataCell>
              <code class="text-medium-emphasis small">{{ companyUser.user.email }}</code>
            </CTableDataCell>
            <CTableDataCell>
              <CBadge :color="getRoleColor(companyUser.role)">
                {{ ROLES[companyUser.role].name }}
              </CBadge>
            </CTableDataCell>
            <CTableDataCell>
              <div class="small text-medium-emphasis">
                {{ getSiteAccessText(companyUser) }}
              </div>
            </CTableDataCell>
            <CTableDataCell>
              <CButtonGroup size="sm">
                <CTooltip
                  v-if="permissions?.company_users.update && canManageUser(companyUser) && companyUser.user.id !== currentUser?.id"
                  content="Change role">
                  <template #toggler="{ id, on }">
                    <CButton
                      v-on="on"
                      color="light"
                      @click="openChangeRoleModal(companyUser)">
                      <CIcon name="cilPencil" />
                    </CButton>
                  </template>
                </CTooltip>
                <CTooltip
                  v-if="(permissions?.company_users.destroy && canManageUser(companyUser)) || companyUser.user.id === currentUser?.id"
                  :content="companyUser.user.id === currentUser?.id ? 'Leave Company' : 'Delete user'">
                  <template #toggler="{ id, on }">
                    <CButton
                      v-if="companyUser.user.id === currentUser?.id"
                      v-on="on"
                      color="light"
                      @click="openDeleteUserModal(companyUser)">
                      <CIcon name="cilRunning" />
                    </CButton>
                    <CButton
                      v-else
                      v-on="on"
                      color="light"
                      @click="openDeleteUserModal(companyUser)">
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
              ({{ invitation.status === 'expired' ? 'Expired' : 'Pending' }} invitation)
            </CTableDataCell>
            <CTableDataCell>
              <div class="small text-medium-emphasis">
                {{ getSiteAccessText(invitation) }}
              </div>
            </CTableDataCell>
            <CTableDataCell>
              <CButtonGroup size="sm">
                <CTooltip
                  v-if="permissions?.invitations.resend && canManageUser(invitation)"
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
                  v-if="permissions?.invitations.destroy && canManageUser(invitation)"
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
      :companyUser="editingCompanyUser"
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
        <p v-if="companyUserToDelete?.user.id === currentUser?.id">
          Leave the company?
        </p>
        <p v-else>
          Delete <strong>{{ companyUserToDelete?.user.name }}</strong> from your organization?
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
          :disabled="isDeletingCompanyUser"
          @click="handleDeleteCompanyUser">
          <CSpinner v-if="isDeletingCompanyUser" size="sm" class="me-2" />
          {{ isDeletingCompanyUser ? 'Deleting...' : 'Delete User' }}
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
  import type { CompanyUser, Invitation } from '../types/invitation';

  const { currentUser, currentRole, accessibleSites } = useAuth();
  const { permissions } = usePermissions();
  const { execute } = useApiCall();

  const companyUsers = ref<CompanyUser[]>([]);
  const invitations = ref<Invitation[]>([]);

  const showInviteModal = ref(false);

  const showChangeRoleModal = ref(false);
  const editingCompanyUser = ref<CompanyUser | null>(null);

  const showDeleteModal = ref(false);
  const companyUserToDelete = ref<CompanyUser | null>(null);
  const isDeletingCompanyUser = ref(false);

  const showDeleteInvitationModal = ref(false);
  const invitationToDelete = ref<Invitation | null>(null);
  const isDeletingInvitation = ref(false);

  function openInviteModal() {
    showInviteModal.value = true;
  }

  function closeInviteModal() {
    showInviteModal.value = false;
  }

  function canManageUser(userable: CompanyUser | Invitation) {
    if (!currentRole.value)
      return false;

    const currentLevel = ROLES[currentRole.value].level;
    const userLevel = ROLES[userable.role].level;

    return currentLevel >= userLevel;
  }

  function companyUserHasOtherSites(userable: CompanyUser | Invitation) {
    return userable.total_sites_count > userable.visible_site_ids.length;
  }

  function getSiteAccessText(userable: CompanyUser | Invitation) {
    if (!ROLES[userable.role].siteSpecific)
      return 'All sites of the company';

    const accessSites = userable.visible_site_ids.map((sid) =>
      accessibleSites.value?.find((site) => site.id === sid)?.name || '●') || [];
    let accessText = accessSites.join(', ');
    if (companyUserHasOtherSites(userable))
      accessText += ` (and ${userable.total_sites_count - (userable.visible_site_ids.length)} more)`;
    return accessText;
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

  function openChangeRoleModal(companyUser: CompanyUser) {
    editingCompanyUser.value = companyUser;
    showChangeRoleModal.value = true;
  }

  function closeChangeRoleModal() {
    showChangeRoleModal.value = false;
    editingCompanyUser.value = null;
  }

  function openDeleteUserModal(companyUser: CompanyUser) {
    companyUserToDelete.value = companyUser;
    showDeleteModal.value = true;
  }

  function closeDeleteUserModal() {
    showDeleteModal.value = false;
    companyUserToDelete.value = null;
  }

  function openDeleteInvitationModal(invitation: Invitation) {
    invitationToDelete.value = invitation;
    showDeleteInvitationModal.value = true;
  }

  function closeDeleteInvitationModal() {
    showDeleteInvitationModal.value = false;
    invitationToDelete.value = null;
  }

  async function handleRoleUpdated(updatedCompanyUser: CompanyUser) {
    const companyUserUpdated = companyUsers.value.find((u) => u.id === updatedCompanyUser.id);
    if (companyUserUpdated)
      Object.assign(companyUserUpdated, updatedCompanyUser);

    closeChangeRoleModal();
  }

  async function handleDeleteCompanyUser() {
    if (!companyUserToDelete.value)
      return;

    isDeletingCompanyUser.value = true;

    const url = ROUTES.company_users_destroy.path.replace(':id', String(companyUserToDelete.value.id));
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
      const index = companyUsers.value.findIndex((u) => u.id === companyUserToDelete.value!.id);
      if (index > -1)
        companyUsers.value.splice(index, 1);

      closeDeleteUserModal();
    }

    isDeletingCompanyUser.value = false;
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
      loadCompanyUsers(),
      loadInvitations()
    ]);
  }

  async function loadCompanyUsers() {
    const { success, data } = await execute<CompanyUser[]>(
      () => axios.get(ROUTES.company_users_index.path),
      { errorTitle: 'Load Users Error',   showErrorToast: true }
    );

    if (success)
      companyUsers.value = data;
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
