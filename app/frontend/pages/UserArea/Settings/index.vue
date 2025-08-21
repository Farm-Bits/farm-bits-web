<template>
  <div class="page-container py-4">
    <CContainer class="mx-auto">
      <CCard class="shadow-sm">
        <!-- Tab Navigation -->
        <CCardHeader class="p-0">
          <CTabs v-model:active-item-key="activeTab" variant="tabs">
            <CTabList variant="tabs" class="nav-tabs-custom">
              <CTab item-key="client" class="tab-item">
                <CIcon name="cilBuilding" class="me-2" />
                Company Information
              </CTab>
              <CTab item-key="users" class="tab-item">
                <CIcon name="cilPeople" class="me-2" />
                Users
              </CTab>
              <CTab item-key="danger" class="tab-item tab-danger">
                <CIcon name="cilWarning" class="me-2" />
                Danger Zone
              </CTab>
            </CTabList>

            <!-- Tab Content -->
            <CTabContent class="p-0">
              <CTabPanel item-key="client">
                <ClientTab />
              </CTabPanel>

              <!-- Users Tab -->
              <CTabPanel item-key="users">
                <UsersTab
                  :users="users"
                  :available-roles="availableRoles"
                  @invite-user="handleUserInvite"
                  @update-user-role="handleUserRoleUpdate"
                  @remove-user="handleUserRemove"
                  @resend-invitation="handleResendInvitation" />
              </CTabPanel>

              <!-- Danger Zone Tab -->
              <CTabPanel item-key="danger">
                <DangerTab />
              </CTabPanel>
            </CTabContent>
          </CTabs>
        </CCardHeader>
      </CCard>
    </CContainer>
  </div>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import ClientTab from './ClientTab.vue';
  import UsersTab from './UsersTab.vue';
  import DangerTab from './DangerTab.vue';
  import useAuth from '@/composables/useAuth';

  const { client, paths } = useAuth();

  // Props (you can receive these from your backend)
  interface Props {
    initialUsers?: any[];
  }

  const props = withDefaults(defineProps<Props>(), {
    initialUsers: () => [
      {
        id: 1,
        name: 'John Doe',
        email: 'john@acme.com',
        role: 'owner',
        status: 'joined',
        avatar: null
      },
      {
        id: 2,
        name: 'Jane Smith',
        email: 'jane@acme.com',
        role: 'admin',
        status: 'joined',
        avatar: null
      },
      {
        id: 3,
        name: 'Bob Johnson',
        email: 'bob@acme.com',
        role: 'manager',
        status: 'pending',
        avatar: null
      }
    ]
  });

  // Tab management
  const activeTab = ref('client');

  const users = ref([...props.initialUsers]);

  // Available roles (from your RoleManageable concern)
  const availableRoles = [
    { key: 'viewer', label: 'Viewer - Read-only access' },
    { key: 'manager', label: 'Manager - Edit access to assigned sites' },
    { key: 'admin', label: 'Admin - Full access except billing' },
    { key: 'owner', label: 'Owner - Full access including billing' }
  ];

  async function handleUserInvite(inviteData: { email: string; role: string }) {
    try {
      // Make API call to invite user
      console.log('Inviting user:', inviteData);

      // Add to local users list with pending status
      const newUser = {
        id: Date.now(),
        name: inviteData.email.split('@')[0],
        email: inviteData.email,
        role: inviteData.role,
        status: 'pending',
        avatar: null
      };

      users.value.push(newUser);

      // You can add success notification here
    } catch (error) {
      console.error('Failed to invite user:', error);
      // Handle error
    }
  }

  async function handleUserRoleUpdate(userId: number, newRole: string) {
    try {
      // Make API call to update user role
      console.log(`Updating user ${userId} role to:`, newRole);

      // Update local state
      const user = users.value.find(u => u.id === userId);
      if (user) {
        user.role = newRole;
      }

      // You can add success notification here
    } catch (error) {
      console.error('Failed to update user role:', error);
      // Handle error
    }
  }

  async function handleUserRemove(userId: number) {
    try {
      // Make API call to remove user
      console.log('Removing user:', userId);

      // Remove from local state
      const index = users.value.findIndex(u => u.id === userId);
      if (index > -1) {
        users.value.splice(index, 1);
      }

      // You can add success notification here
    } catch (error) {
      console.error('Failed to remove user:', error);
      // Handle error
    }
  }

  async function handleResendInvitation(userId: number) {
    try {
      // Make API call to resend invitation
      console.log('Resending invitation for user:', userId);

      // You can add success notification here
    } catch (error) {
      console.error('Failed to resend invitation:', error);
      // Handle error
    }
  }
</script>

<style scoped>
  .nav-tabs-custom .tab-item {
    padding: 1rem 1.5rem;
    border-bottom: 2px solid transparent;
    color: #6c757d;
    text-decoration: none;
    transition: all 0.2s;
  }

  .nav-tabs-custom .tab-item:hover {
    color: #495057;
    border-bottom-color: #dee2e6;
  }

  .nav-tabs-custom .tab-item.active {
    color: #0d6efd;
    border-bottom-color: #0d6efd;
    background-color: transparent;
  }

  .nav-tabs-custom .tab-danger {
    color: #dc3545;
  }

  .nav-tabs-custom .tab-danger:hover {
    color: #b02a37;
    border-bottom-color: #f5c2c7;
  }

  .nav-tabs-custom .tab-danger.active {
    color: #dc3545;
    border-bottom-color: #dc3545;
  }

  .page-container {
    background-color: #f8f9fa;
    min-height: 100vh;
  }
</style>
