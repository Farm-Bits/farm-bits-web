<template>
  <div class="p-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <h5 class="mb-0">Company Users</h5>
      <CButton
        color="primary"
        @click="showInviteModal = true">
        <CIcon name="cilUserPlus" class="me-2" />
        Invite User
      </CButton>
    </div>

    <!-- Users Table -->
    <div class="table-responsive">
      <CTable hover responsive>
        <CTableHead>
          <CTableRow>
            <CTableHeaderCell>Name</CTableHeaderCell>
            <CTableHeaderCell>Email</CTableHeaderCell>
            <CTableHeaderCell>Role</CTableHeaderCell>
            <CTableHeaderCell>Status</CTableHeaderCell>
            <CTableHeaderCell width="50"></CTableHeaderCell>
          </CTableRow>
        </CTableHead>
        <CTableBody>
          <!-- Users -->
          <CTableRow v-for="clientUser in clientUsers" :key="clientUser.id">
            <CTableDataCell>
              <div class="d-flex align-items-center">
                {{ clientUser.user.name }}
              </div>
            </CTableDataCell>
            <CTableDataCell>{{ clientUser.user.email }}</CTableDataCell>
            <CTableDataCell>
              {{ ROLES[clientUser.role].name }}
            </CTableDataCell>
            <CTableDataCell>
              <CBadge color="success">Active</CBadge>
            </CTableDataCell>
            <CTableDataCell>
              <CDropdown
                variant="btn-group"
                placement="bottom-end">
                <CDropdownToggle
                  size="sm"
                  :caret="false">
                  <CIcon name="cilOptions" />
                </CDropdownToggle>
                <Teleport to="body">
                  <CDropdownMenu>
                    <CDropdownItem
                      v-if="clientUser.user_id !== pageProps.user.id"
                      @click="openChangeRoleModal(clientUser)">
                      <CIcon name="cilPeople" class="me-2" />
                      Change Role
                    </CDropdownItem>
                    <CDropdownDivider v-if="clientUser.user_id !== pageProps.user.id" />
                    <CDropdownItem
                      @click="handleUserRemove(clientUser)"
                      class="text-danger">
                      <CIcon name="cilUserX" class="me-2" />
                      {{ clientUser.user_id !== pageProps.user.id ? 'Remove User' : 'Leave Company' }}
                    </CDropdownItem>
                  </CDropdownMenu>
                </Teleport>
              </CDropdown>
            </CTableDataCell>
          </CTableRow>

          <!-- Invitations -->
          <CTableRow v-for="invitation in invitations" :key="`inv-${invitation.id}`">
            <CTableDataCell>
              <div class="d-flex align-items-center text-muted">
                <em>Invited user</em>
              </div>
            </CTableDataCell>
            <CTableDataCell>{{ invitation.email }}</CTableDataCell>
            <CTableDataCell>
              {{ ROLES[invitation.role].name }}
            </CTableDataCell>
            <CTableDataCell>
              <CBadge
                :color="invitation.status === 'pending' ? 'warning' : 'danger'">
                {{ invitation.status === 'pending' ? 'Pending' : 'Expired' }}
              </CBadge>
            </CTableDataCell>
            <CTableDataCell>
              <CDropdown
                variant="btn-group"
                placement="bottom-end">
                <CDropdownToggle
                  size="sm"
                  :caret="false">
                  <CIcon name="cilOptions" />
                </CDropdownToggle>
                <Teleport to="body">
                  <CDropdownMenu>
                    <CDropdownItem @click="handleResendInvitation(invitation)">
                      <CIcon name="cilEnvelopeClosed" class="me-2" />
                      Resend Invitation
                    </CDropdownItem>
                    <CDropdownDivider />
                    <CDropdownItem
                      @click="handleInvitationRemove(invitation)"
                      class="text-danger">
                      <CIcon name="cilUserX" class="me-2" />
                      Cancel Invitation
                    </CDropdownItem>
                  </CDropdownMenu>
                </Teleport>
              </CDropdown>
            </CTableDataCell>
          </CTableRow>
        </CTableBody>
      </CTable>
    </div>

    <!-- Invite User Modal Component -->
    <InviteUserModal
      :visible="showInviteModal"
      @close="showInviteModal = false"
      @invite="handleUserInvite" />

    <!-- Change Role Modal Component -->
    <ChangeRoleModal
      :visible="showRoleModal"
      :clientUser="selectedClientUser"
      @close="closeRoleModal"
      @update="handleUpdateUserRole" />
  </div>
</template>

<script lang="ts" setup>
  import { ref, onMounted } from 'vue';
  import axios from 'axios';
  import ChangeRoleModal, { type ChangeRoleData } from '../modals/ChangeRoleModal.vue';
  import InviteUserModal, { type InvitationData } from '../modals/InviteUserModal.vue';
  import useAuth from '@/composables/useAuth';
  import usePermissions from '@/composables/usePermissions';
  import { useApiCall, type ApiError } from '@/composables/useApi';
  import { ROLES, ROUTES } from '@/types/permissions';
  import type { ClientUser, Invitation } from '../types/invitation';
  import { type User } from '@/types/inertia';

  const { pageProps } = useAuth<{
    user: User;
  }>();

  const { permissions } = usePermissions();
  const { execute } = useApiCall();

  const clientUsers = ref<ClientUser[]>([]);
  const invitations = ref<Invitation[]>([]);
  const showInviteModal = ref(false);
  const showRoleModal = ref(false);
  const selectedClientUser = ref<ClientUser | null>(null);

  function openChangeRoleModal(user: ClientUser) {
    selectedClientUser.value = user;
    showRoleModal.value = true;
  }

  function closeRoleModal() {
    showRoleModal.value = false;
    selectedClientUser.value = null;
  }

  async function handleUserRemove(clientUserToRemove: ClientUser) {
    if (!confirm(`Are you sure you want to remove ${clientUserToRemove.user.name} from the company?`))
      return;

    const url = ROUTES.client_users_destroy.path.replace(':id', String(clientUserToRemove.id));
    const { success } = await execute(
      () => axios.delete(
        url,
        { data: { client_user: { user_id: clientUserToRemove.user_id } } }
      ),
      {
        showSuccessToast: true,
        successMessage: 'User removed successfully',
        showErrorToast: true,
        errorTitle: 'Remove User Error'
      }
    );

    if (success) {
      const index = clientUsers.value.findIndex((u) => u.id === clientUserToRemove.user_id);
      if (index > -1)
        clientUsers.value.splice(index, 1);
    }
  }

  async function handleResendInvitation(invitation: Invitation) {
    const url = ROUTES.invitations_resend.path.replace(':id', String(invitation.id));
    await execute(
      () => axios.put(url),
      {
        showSuccessToast: true,
        successMessage: 'Invitation resent successfully',
        showErrorToast: true,
        errorTitle: 'Resend Invitation Error'
      }
    );
  }

  async function handleInvitationRemove(invitation: Invitation) {
    if (!confirm(`Are you sure you want to cancel the invitation for ${invitation.email}?`))
      return;

    const url = ROUTES.invitations_destroy.path.replace(':id', String(invitation.id));
    const { success } = await execute(
      () => axios.delete(url),
      {
        showSuccessToast: true,
        successMessage: 'Invitation removed successfully',
        showErrorToast: true,
        errorTitle: 'Remove Invitation Error'
      }
    );

    if (success) {
      const index = invitations.value.findIndex((i) => i.id === invitation.id);
      if (index > -1)
        invitations.value.splice(index, 1);
    }
  }

  async function handleUpdateUserRole(
    changeRoleData: ChangeRoleData,
    callback?: (success: boolean, error?: ApiError) => void
  ) {
    const url = ROUTES.client_users_update.path.replace(':id', String(changeRoleData.clientUserId));
    const { success, data, error } = await execute<ClientUser>(
      () => axios.put(
        url,
        { client_user: { user_id: changeRoleData.userId, role: changeRoleData.role } }
      ),
      {
        showSuccessToast: true,
        successMessage: 'Role updated successfully'
      }
    );

    if (success) {
      const clientUserUpdated = clientUsers.value.find((u) => u.id === changeRoleData.userId);
      if (clientUserUpdated)
        clientUserUpdated.role = data.role;

      closeRoleModal();
    }

    callback?.(success, error);
  }

  async function handleUserInvite(
    inviteData: InvitationData,
    callback?: (success: boolean, error?: ApiError) => void
  ) {
    const { success, data, error } = await execute<Invitation>(
      () => axios.post(ROUTES.invitations_create.path, { invitation: inviteData }),
      { showSuccessToast: true, successMessage: 'Invitation sent successfully' }
    );

    if (success) {
      invitations.value.push(data);
      showInviteModal.value = false;
    }

    callback?.(success, error);
  }

  async function fetchUsers() {
    const { success, data } = await execute<ClientUser[]>(
      () => axios.get(ROUTES.client_users_index.path),
      { errorTitle: 'Load Users Error', showErrorToast: true }
    );

    if (success)
      clientUsers.value = data;
  }

  async function fetchInvitations() {
    const { success, data } = await execute<Invitation[]>(
      () => axios.get(ROUTES.invitations_index.path),
      { errorTitle: 'Load Invitations Error', showErrorToast: true }
    );

    if (success)
      invitations.value = data;
  }

  onMounted(() => {
    fetchUsers();
    fetchInvitations();
  });
</script>

<style scoped>
  .table-responsive {
    position: relative;
  }
</style>
