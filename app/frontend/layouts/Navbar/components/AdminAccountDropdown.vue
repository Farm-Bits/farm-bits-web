<template>
  <div class="dropdown">
    <button
      class="btn btn-link nav-link py-2 px-0 px-lg-2 d-flex align-items-center"
      type="button"
      @click="toggleDropdown"
      ref="dropdownToggle">
      <CAvatar size="md" color="danger">
        {{ getInitials(pageProps.user.name) }}
      </CAvatar>
    </button>

    <div
      :class="['dropdown-menu', 'dropdown-menu-end', { show: isOpen }]"
      ref="dropdownMenu">
      <div class="dropdown-header d-flex align-items-center mb-2">
        <CAvatar size="sm" color="danger" class="me-2">
          {{ getInitials(pageProps.user.name) }}
        </CAvatar>
        <div class="user-info">
          <div class="fw-semibold">{{ pageProps.user.name }}</div>
          <small class="text-muted">System Administrator</small>
        </div>
      </div>

      <CDropdownDivider />

      <CDropdownHeader>Account</CDropdownHeader>

      <CDropdownItem
        class="d-flex align-items-center"
        @click="router.visit(paths.pages.myAccount)">
        <CIcon icon="cilUser" class="me-2" />
        Profile
      </CDropdownItem>

      <CDropdownItem href="#/admin/system-settings" class="d-flex align-items-center">
        <CIcon icon="cilSettings" class="me-2" />
        System Settings
      </CDropdownItem>

      <CDropdownDivider />

      <CDropdownHeader>Administration</CDropdownHeader>

      <CDropdownItem href="#/admin/users" class="d-flex align-items-center">
        <CIcon icon="cilPeople" class="me-2" />
        Manage Users
      </CDropdownItem>

      <CDropdownItem href="#/admin/clients" class="d-flex align-items-center">
        <CIcon icon="cilBuilding" class="me-2" />
        Manage Companies
      </CDropdownItem>

      <CDropdownItem href="#/admin/logs" class="d-flex align-items-center">
        <CIcon icon="cilNotes" class="me-2" />
        System Logs
      </CDropdownItem>

      <CDropdownDivider />

      <CDropdownItem
        class="d-flex align-items-center text-danger cursor-pointer"
        @click="router.delete(paths.actions.signOut)">
        <CIcon icon="cilAccountLogout" class="me-2" />
        Sign Out
      </CDropdownItem>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { ref, onMounted, onUnmounted } from 'vue';
  import { router } from '@inertiajs/vue3';
  import useAuth from '@/composables/useAuth';
  import { type User } from '@/types/inertia';

  const { pageProps, paths } = useAuth<{
    user: User;
  }>();

  const isOpen = ref(false);
  const dropdownToggle = ref<HTMLElement | null>(null);
  const dropdownMenu = ref<HTMLElement | null>(null);

  const toggleDropdown = () => {
    isOpen.value = !isOpen.value;
  };

  const getInitials = (name: string) => {
    return (name.match(/\b\w/g) || []).join('').toUpperCase();
  };

  const handleClickOutside = (event: MouseEvent) => {
    if (
      dropdownToggle.value &&
      dropdownMenu.value &&
      !dropdownToggle.value.contains(event.target as Node) &&
      !dropdownMenu.value.contains(event.target as Node)
    ) {
      isOpen.value = false;
    }
  };

  onMounted(() => {
    document.addEventListener('click', handleClickOutside);
  });

  onUnmounted(() => {
    document.removeEventListener('click', handleClickOutside);
  });
</script>

<style scoped>
  .dropdown-menu {
    position: absolute;
    top: 100%;
    right: 0;
    z-index: 1000;
    width: 240px;
    padding-bottom: 0.5rem;
    border: 1px solid var(--cui-border-color);
    border-radius: 0.375rem;
    background-color: var(--cui-dropdown-bg);
    box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15);
    transform: translateY(0.5rem);
  }

  .user-info {
    flex: 1;
    min-width: 0;
  }

  .user-info .fw-semibold {
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .btn-link {
    border: none;
    background: none;
    text-decoration: none;
    font-size: inherit;
  }

  .btn-link:hover {
    text-decoration: none;
    color: var(--cui-danger) !important;
  }

  /* Admin-specific styling */
  .dropdown-header {
    color: var(--cui-danger);
    font-weight: 600;
  }
</style>
