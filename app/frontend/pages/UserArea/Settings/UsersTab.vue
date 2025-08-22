<!-- UsersTab.vue -->
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
        <CTableRow v-for="user in users" :key="user.id">
          <CTableDataCell>
            <div class="d-flex align-items-center">
              {{ user.name }}
            </div>
          </CTableDataCell>
          <CTableDataCell>{{ user.email }}</CTableDataCell>
          <CTableDataCell>
            <CBadge
              :color="getRoleColor(user.role)"
              class="text-capitalize">
              {{ user.role }}
            </CBadge>
          </CTableDataCell>
          <CTableDataCell>
            <CBadge
              :color="getStatusColor(user.status)"
              class="text-capitalize">
              {{ user.status }}
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
              <CDropdownMenu>
                <CDropdownItem
                  @click="changeUserRole(user)"
                  :disabled="user.role === 'owner'">
                  <CIcon name="cilPeople" class="me-2" />
                  Change Role
                </CDropdownItem>
                <CDropdownItem
                  v-if="user.status !== 'joined'"
                  @click="handleResendInvitation(user)">
                  <CIcon name="cilEnvelopeClosed" class="me-2" />
                  Resend Invitation
                </CDropdownItem>
                <CDropdownDivider />
                <CDropdownItem
                  @click="handleUserRemove(user)"
                  :disabled="user.role === 'owner'"
                  class="text-danger">
                  <CIcon name="cilUserX" class="me-2" />
                  Remove User
                </CDropdownItem>
              </CDropdownMenu>
            </CDropdown>
          </CTableDataCell>
        </CTableRow>
      </CTableBody>
    </CTable>

    <!-- Invite User Modal -->
    <CModal
      :visible="showInviteModal"
      @close="closeInviteModal"
      backdrop="static">
      <CModalHeader>
        <CModalTitle>Invite User</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <CForm @submit.prevent="handleUserInvite">
          <div class="mb-3">
            <CFormLabel for="inviteEmail">Email Address *</CFormLabel>
            <CFormInput
              id="inviteEmail"
              v-model="inviteForm.email"
              type="email"
              placeholder="user@example.com"
              :invalid="!!inviteFormErrors.email"
              required />
            <CFormFeedback :invalid="true" v-if="inviteFormErrors.email">
              {{ inviteFormErrors.email }}
            </CFormFeedback>
          </div>
          <div class="mb-3">
            <CFormLabel>Role *</CFormLabel>
            <div class="mt-2">
              <CFormCheck
                v-for="role in availableRoles"
                :key="role.key"
                :id="`role-${role.key}`"
                v-model="inviteForm.role"
                :value="role.key"
                type="radio"
                :label="role.label"
                class="mb-2" />
            </div>
          </div>
        </CForm>
      </CModalBody>
      <CModalFooter>
        <CButton
          color="secondary"
          @click="closeInviteModal">
          Cancel
        </CButton>
        <CButton
          color="primary"
          @click="handleUserInvite"
          :disabled="!inviteForm.email || !inviteForm.role">
          Send Invitation
        </CButton>
      </CModalFooter>
    </CModal>

    <!-- Change Role Modal -->
    <CModal
      :visible="showRoleModal"
      @close="closeRoleModal"
      backdrop="static">
      <CModalHeader>
        <CModalTitle>Change User Role</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <p class="mb-3">
          Change role for <strong>{{ selectedUser?.name }}</strong>
        </p>
        <div class="mb-3">
          <CFormLabel>Select Role</CFormLabel>
          <div class="mt-2">
            <CFormCheck
              v-for="role in availableRoles"
              :key="role.key"
              :id="`change-role-${role.key}`"
              v-model="roleChangeForm.role"
              :value="role.key"
              type="radio"
              :label="role.label"
              class="mb-2" />
          </div>
        </div>
      </CModalBody>
      <CModalFooter>
        <CButton
          color="secondary"
          @click="closeRoleModal">
          Cancel
        </CButton>
        <CButton
          color="primary"
          @click="handleUserRoleUpdate"
          :disabled="!hasRoleChanged">
          Update Role
        </CButton>
      </CModalFooter>
    </CModal>
  </div>
</template>

<script lang="ts" setup>
  import { ref, reactive, computed, onMounted } from 'vue';
  import useAuth from '@/composables/useAuth';
  import { type User } from '@/types/inertia';

  type InvitationStatus = 'pending' | 'expired' | 'joined';

  type KeyRole = 'owner' | 'admin' | 'manager' | 'viewer';

  type ClientUser = User & {
    role: KeyRole;
    status: InvitationStatus;
  };

  const { paths } = useAuth();

  const users = ref<ClientUser[]>([]);

  const availableRoles = [
    { key: 'viewer', label: 'Viewer - Read-only access' },
    { key: 'manager', label: 'Manager - Edit access to assigned sites' },
    { key: 'admin', label: 'Admin - Full access except billing' },
    { key: 'owner', label: 'Owner - Full access including billing' }
  ];

  const showInviteModal = ref(false);
  const showRoleModal = ref(false);

  const inviteForm = reactive({
    email: '',
    role: 'viewer' as KeyRole
  });
  const inviteFormErrors = reactive({
    email: ''
  });

  const selectedUser = ref<ClientUser | null>(null);
  const roleChangeForm = reactive<{
    role: KeyRole | null
  }>({
    role: null
  });

  const hasRoleChanged = computed(() => {
    return roleChangeForm.role !== selectedUser.value?.role;
  });

  function getRoleColor(role: KeyRole) {
    const colors = {
      owner: 'danger',
      admin: 'warning',
      manager: 'info',
      viewer: 'secondary'
    };
    return colors[role] || 'secondary';
  }

  function getStatusColor(status: InvitationStatus) {
    const colors = {
      joined: 'success',
      pending: 'warning',
      expired: 'danger'
    };
    return colors[status] || 'secondary';
  }

  function changeUserRole(user: ClientUser) {
    selectedUser.value = user;
    roleChangeForm.role = user.role;
    showRoleModal.value = true;
  }

  async function handleUserRoleUpdate() {
    if (!selectedUser.value || !hasRoleChanged.value)
      return;

    selectedUser.value.id, roleChangeForm.role
    try {
      // Make API call to update user role
      console.log(`Updating user ${selectedUser.value.id} role to:`, roleChangeForm.role);

      // Update local state
      const user = users.value.find(u => u.id === selectedUser.value!.id);
      if (user && roleChangeForm.role)
        user.role = roleChangeForm.role;

      // You can add success notification here
      closeRoleModal();
    } catch (error) {
      console.error('Failed to update user role:', error);
      // Handle error
    }
  }

  async function handleUserRemove(user: ClientUser) {
    if (confirm(`Are you sure you want to remove ${user.name} from the company?`)) {
      try {
        // Make API call to remove user
        console.log('Removing user:', user.id);

        // Remove from local state
        const index = users.value.findIndex(u => u.id === user.id);
        if (index > -1)
          users.value.splice(index, 1);

        // You can add success notification here
      } catch (error) {
        console.error('Failed to remove user:', error);
        // Handle error
      }
    }
  }

  async function handleResendInvitation(user: ClientUser) {
    try {
      // Make API call to resend invitation
      console.log('Resending invitation for user:', user.id);

      // You can add success notification here
    } catch (error) {
      console.error('Failed to resend invitation:', error);
      // Handle error
    }
  }

  async function handleUserInvite() {
    inviteFormErrors.email = '';

    if (!inviteForm.email) {
      inviteFormErrors.email = 'Email is required';
      return;
    }

    if (!/\S+@\S+\.\S+/.test(inviteForm.email)) {
      inviteFormErrors.email = 'Please enter a valid email';
      return;
    }

    if (users.value.some(u => u.email === inviteForm.email)) {
      inviteFormErrors.email = 'User with this email already exists';
      return;
    }

    try {
      // Make API call to invite user
      console.log('Inviting user:', inviteForm);

      // Add to local users list with pending status
      const newUser = {
        id: Date.now(),
        name: inviteForm.email.split('@')[0],
        email: inviteForm.email,
        role: inviteForm.role,
        status: 'pending' as InvitationStatus,
        avatar: null
      };

      users.value.push(newUser);

      // You can add success notification here
      closeInviteModal();
    } catch (error) {
      console.error('Failed to invite user:', error);
      // Handle error
    }
  }

  function closeInviteModal() {
    showInviteModal.value = false;
    inviteForm.email = '';
    inviteForm.role = 'viewer';
    inviteFormErrors.email = '';
  }

  function closeRoleModal() {
    showRoleModal.value = false;
    selectedUser.value = null;
    roleChangeForm.role = null;
  }

  function fetchUsers() {
    fetch(paths.value.api.users)
      .then(response => response.json())
      .then(data => {
        users.value = data;
      });
  }

  onMounted(() => {
    fetchUsers();
  });
</script>

<style scoped>
</style>
