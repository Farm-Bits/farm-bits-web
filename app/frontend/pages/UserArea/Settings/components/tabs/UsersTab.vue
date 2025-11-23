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
          <CTableRow v-for="user in users" :key="user.id">
            <CTableDataCell>
              <div class="d-flex align-items-center">
                {{ user.name }}
              </div>
            </CTableDataCell>
            <CTableDataCell>{{ user.email }}</CTableDataCell>
            <CTableDataCell>
              {{ ROLES[user.role].name }}
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
                      v-if="user.id !== pageProps.user.id"
                      @click="openChangeRoleModal(user)">
                      <CIcon name="cilPeople" class="me-2" />
                      Change Role
                    </CDropdownItem>
                    <CDropdownDivider v-if="user.id !== pageProps.user.id" />
                    <CDropdownItem
                      @click="handleUserRemove(user)"
                      class="text-danger">
                      <CIcon name="cilUserX" class="me-2" />
                      {{ user.id !== pageProps.user.id ? 'Remove User' : 'Leave Company' }}
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
      :user="selectedUser"
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
  import { useApiCall, type ApiError } from '@/composables/useApi';
  import { ROLES } from '@/types/permissions';
  import type { ClientUser, Invitation } from '../types/invitation';
  import { type User } from '@/types/inertia';

  const { pageProps, paths } = useAuth<{
    user: User;
  }>();

  const { execute } = useApiCall();

  const users = ref<ClientUser[]>([]);
  const invitations = ref<Invitation[]>([]);
  const showInviteModal = ref(false);
  const showRoleModal = ref(false);
  const selectedUser = ref<ClientUser | null>(null);

  function openChangeRoleModal(user: ClientUser) {
    selectedUser.value = user;
    showRoleModal.value = true;
  }

  function closeRoleModal() {
    showRoleModal.value = false;
    selectedUser.value = null;
  }

  async function handleUserRemove(user: ClientUser) {
    if (!confirm(`Are you sure you want to remove ${user.name} from the company?`))
      return;

    const { success } = await execute(
      () => axios.delete(
        paths.value.api.users,
        { data: { client_user: { user_id: user.id } } }
      ),
      {
        showSuccessToast: true,
        successMessage: 'User removed successfully',
        showErrorToast: true,
        errorTitle: 'Remove User Error'
      }
    );

    if (success) {
      const index = users.value.findIndex((u) => u.id === user.id);
      if (index > -1)
        users.value.splice(index, 1);
    }
  }

  async function handleResendInvitation(invitation: Invitation) {
    await execute(
      () => axios.put(`${paths.value.api.invitations}/${invitation.id}/resend`),
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

    const { success } = await execute(
      () => axios.delete(`${paths.value.api.invitations}/${invitation.id}`),
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
    const { success, data, error } = await execute<ClientUser>(
      () => axios.put(
        paths.value.api.users,
        { client_user: { user_id: changeRoleData.userId, role: changeRoleData.role } }
      ),
      {
        showSuccessToast: true,
        successMessage: 'Role updated successfully'
      }
    );

    if (success) {
      const user = users.value.find((u) => u.id === changeRoleData.userId);
      if (user)
        user.role = data.role;

      closeRoleModal();
    }

    callback?.(success, error);
  }

  async function handleUserInvite(
    inviteData: InvitationData,
    callback?: (success: boolean, error?: ApiError) => void
  ) {
    const { success, data, error } = await execute<Invitation>(
      () => axios.post(paths.value.api.invitations, { invitation: inviteData }),
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
      () => axios.get(paths.value.api.users),
      { errorTitle: 'Load Users Error', showErrorToast: true }
    );

    if (success)
      users.value = data;
  }

  async function fetchInvitations() {
    const { success, data } = await execute<Invitation[]>(
      () => axios.get(paths.value.api.invitations),
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
