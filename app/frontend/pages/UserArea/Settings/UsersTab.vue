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
                  @click="resendInvitation(user)">
                  <CIcon name="cilEnvelopeClosed" class="me-2" />
                  Resend Invitation
                </CDropdownItem>
                <CDropdownDivider />
                <CDropdownItem
                  @click="removeUser(user)"
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
        <CForm @submit.prevent="sendInvitation">
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
          @click="sendInvitation"
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
          @click="updateUserRole"
          :disabled="!hasRoleChanged">
          Update Role
        </CButton>
      </CModalFooter>
    </CModal>
  </div>
</template>

<script lang="ts" setup>
  import { ref, reactive, computed } from 'vue';

  type InvitationStatus = 'pending' | 'expired' | 'joined';

  type KeyRole = 'owner' | 'admin' | 'manager' | 'viewer';

  interface User {
    id: number;
    name: string;
    email: string;
    role: KeyRole;
    status: InvitationStatus;
  };

  interface Role {
    key: KeyRole;
    label: string;
  };

  interface Props {
    users: User[];
    availableRoles: Role[];
  };

  const props = defineProps<Props>();

  const emit = defineEmits<{
    inviteUser: [data: { email: string; role: string }];
    updateUserRole: [userId: number, role: string];
    removeUser: [userId: number];
    resendInvitation: [userId: number];
  }>();

  const showInviteModal = ref(false);
  const showRoleModal = ref(false);

  const inviteForm = reactive({
    email: '',
    role: 'viewer'
  });

  const inviteFormErrors = reactive({
    email: ''
  });

  const selectedUser = ref<User | null>(null);
  const roleChangeForm = reactive({
    role: ''
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

  function changeUserRole(user: User) {
    selectedUser.value = user;
    roleChangeForm.role = user.role;
    showRoleModal.value = true;
  }

  function updateUserRole() {
    if (selectedUser.value && hasRoleChanged.value) {
      emit('updateUserRole', selectedUser.value.id, roleChangeForm.role);
      closeRoleModal();
    }
  }

  function removeUser(user: User) {
    if (confirm(`Are you sure you want to remove ${user.name} from the company?`)) {
      emit('removeUser', user.id);
    }
  }

  function resendInvitation(user: User) {
    emit('resendInvitation', user.id);
  }

  function sendInvitation() {
    inviteFormErrors.email = '';

    if (!inviteForm.email) {
      inviteFormErrors.email = 'Email is required';
      return;
    }

    if (!/\S+@\S+\.\S+/.test(inviteForm.email)) {
      inviteFormErrors.email = 'Please enter a valid email';
      return;
    }

    if (props.users.some(u => u.email === inviteForm.email)) {
      inviteFormErrors.email = 'User with this email already exists';
      return;
    }

    emit('inviteUser', {
      email: inviteForm.email,
      role: inviteForm.role
    });

    closeInviteModal();
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
    roleChangeForm.role = '';
  }
</script>

<style scoped>
</style>
