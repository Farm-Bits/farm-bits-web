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
        <!-- Users -->
        <CTableRow v-for="user in users" :key="user.id">
          <CTableDataCell>
            <div class="d-flex align-items-center">
              {{ user.name }}
            </div>
          </CTableDataCell>
          <CTableDataCell>{{ user.email }}</CTableDataCell>
          <CTableDataCell>
            {{ user.role }}
          </CTableDataCell>
          <CTableDataCell>
            Joined
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
                  :disabled="false">
                  <CIcon name="cilPeople" class="me-2" />
                  Change Role
                </CDropdownItem>
                <CDropdownDivider />
                <CDropdownItem
                  @click="handleUserRemove(user)"
                  :disabled="false"
                  class="text-danger">
                  <CIcon name="cilUserX" class="me-2" />
                  Remove User
                </CDropdownItem>
              </CDropdownMenu>
            </CDropdown>
          </CTableDataCell>
        </CTableRow>

        <!-- Invitations -->
        <CTableRow v-for="invitation in invitations" :key="invitation.id">
          <CTableDataCell>
            <div class="d-flex align-items-center">
              <!-- {{ invitation.name }} -->
            </div>
          </CTableDataCell>
          <CTableDataCell>{{ invitation.email }}</CTableDataCell>
          <CTableDataCell>
            {{ invitation.role }}
          </CTableDataCell>
          <CTableDataCell>
            {{ invitation.status }}
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
                <CDropdownItem @click="handleResendInvitation(invitation)">
                  <CIcon name="cilEnvelopeClosed" class="me-2" />
                  Resend Invitation
                </CDropdownItem>
                <CDropdownDivider />
                <CDropdownItem
                  @click="handleInvitationRemove(invitation)"
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
              name="email"
              placeholder="Enter email"
              type="email"
              required
              v-model="inviteForm.invitation.email"
              :invalid="v$.invitation.email.$error" />
            <div class="form-error" v-if="v$.invitation.email.$error">
              {{ v$.invitation.email.$errors[0].$message }}
            </div>
          </div>
          <div class="mb-3">
            <CFormLabel>Role *</CFormLabel>
            <div class="mt-2">
              <CFormCheck
                v-for="role in roles"
                :key="role.id"
                :id="`role-${role.id}`"
                v-model="inviteForm.invitation.role"
                :value="role.id"
                :label="role.name"
                type="radio"
                class="mb-2" />
              <div class="form-error" v-if="v$.invitation.role.$error">
                {{ v$.invitation.role.$errors[0].$message }}
              </div>
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
          :disabled="!isInviteFormValid">
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
              v-for="role in roles"
              :key="role.id"
              :id="`change-role-${role.id}`"
              v-model="roleChangeForm.role"
              :value="role.id"
              type="radio"
              :label="role.name"
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
          @click="handleUpdateUserRole"
          :disabled="!hasRoleChanged">
          Update Role
        </CButton>
      </CModalFooter>
    </CModal>
  </div>
</template>

<script lang="ts" setup>
  import { ref, reactive, computed, onMounted } from 'vue';
  import { useForm } from '@inertiajs/vue3';
  import { useVuelidate } from '@vuelidate/core';
  import axios from 'axios';
  import { email, required } from '@vuelidate/validators';
  import useAuth from '@/composables/useAuth';
  import { type User } from '@/types/inertia';

  type Role = {
    id: 'admin' | 'manager' | 'viewer';
    name: string;
    level: number;
    permissions: {
      [key: string]: boolean;
    };
  };

  type ClientUser = User & {
    role: Role['id'];
    status: InvitationStatus;
  };

  type InvitationStatus = 'pending' | 'expired' | 'cancelled';
  type Invitation = {
    id: number;
    email: string;
    role: Role['id'];
    status: InvitationStatus;
    expired: boolean;
  };

  const { paths, features } = useAuth();

  const users = ref<ClientUser[]>([]);
  const invitations = ref<Invitation[]>([]);
  const roles = ref<Role[]>([]);

  const showInviteModal = ref(false);
  const showRoleModal = ref(false);

  const inviteForm = useForm({
    invitation: {
      email: null,
      role: 'viewer' as Role['id']
    }
  });

  function rules() {
    return {
      invitation: {
        email: { required, email },
        role: { required }
      }
    };
  }

  const v$ = useVuelidate(rules, inviteForm);

  const isInviteFormValid = computed(() => {
    return !v$.value.$invalid;
  });

  const selectedUser = ref<ClientUser | null>(null);
  const roleChangeForm = reactive<{
    role: Role['id'] | null
  }>({
    role: null
  });

  const hasRoleChanged = computed(() => {
    return roleChangeForm.role !== selectedUser.value?.role;
  });

  function changeUserRole(user: ClientUser) {
    selectedUser.value = user;
    roleChangeForm.role = user.role;
    showRoleModal.value = true;
  }

  async function handleUserRemove(user: ClientUser) {
    if (confirm(`Are you sure you want to remove ${user.name} from the company?`)) {
      try {
        console.log('Removing user:', user.id);

        const index = users.value.findIndex(u => u.id === user.id);
        if (index > -1)
          users.value.splice(index, 1);

      } catch (error) {
        console.error('Failed to remove user:', error);
      }
    }
  }

  async function handleResendInvitation(invitation: Invitation) {
    try {
      // Make API call to resend invitation
      console.log('Resending invitation for user:', invitation.id);

      // You can add success notification here
    } catch (error) {
      console.error('Failed to resend invitation:', error);
      // Handle error
    }
  }

  async function handleInvitationRemove(invitation: Invitation) {
    if (confirm(`Are you sure you want to remove the invitation for ${invitation.email}?`)) {
      try {
        // Make API call to remove invitation
        console.log('Removing invitation:', invitation.id);

        // Remove from local state
        const index = invitations.value.findIndex(i => i.id === invitation.id);
        if (index > -1)
          invitations.value.splice(index, 1);

        // You can add success notification here
      } catch (error) {
        console.error('Failed to remove invitation:', error);
        // Handle error
      }
    }
  }

  async function handleUpdateUserRole() {
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

  async function handleUserInvite() {
    // if (!features.value.canRegister)
    //   return;

    const isValid = await v$.value.$validate();
    if (!isValid) {
      const firstInvalidElement = document.querySelector('.is-invalid');
      firstInvalidElement?.scrollIntoView({
        behavior: 'smooth',
        block: 'center'
      });
      return;
    }

    const result = await axios.post(paths.value.api.invitations, {
      invitation: {
        email: inviteForm.invitation.email,
        role: inviteForm.invitation.role
      }
    });

    if (result.status === 201) {
      const newInvitation = {
        id: Date.now(),
        email: inviteForm.invitation.email || '',
        role: inviteForm.invitation.role,
        status: 'pending' as InvitationStatus,
        expired: false
      };

      invitations.value.push(newInvitation);
      closeInviteModal();
    }
  }

  function closeInviteModal() {
    showInviteModal.value = false;
    inviteForm.invitation.email = null;
    inviteForm.invitation.role = 'viewer';
  }

  function closeRoleModal() {
    showRoleModal.value = false;
    selectedUser.value = null;
    roleChangeForm.role = null;
  }

  async function fetchUsers() {
    try {
      const response = await axios.get(paths.value.api.users);
      users.value = response.data;
    } catch (error) {
      console.error('Failed to fetch users:', error);
    }
  }

  async function fetchInvitations() {
    try {
      const response = await axios.get(paths.value.api.invitations);
      invitations.value = response.data;
    } catch (error) {
      console.error('Failed to fetch invitations:', error);
    }
  }

  async function fetchRoles() {
    try {
      const response = await axios.get(paths.value.api.roles);
      roles.value = response.data;
    } catch (error) {
      console.error('Failed to fetch roles:', error);
    }
  }

  onMounted(() => {
    fetchUsers();
    fetchInvitations();
    fetchRoles();
  });
</script>

<style scoped>
</style>
