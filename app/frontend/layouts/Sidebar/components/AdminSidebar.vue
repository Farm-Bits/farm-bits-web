<template>
  <CSidebar
    :narrow="sidebarNarrow"
    :visible="sidebarVisible"
    @visible-change="store.setSidebarVisible"
    minimizer
    colorScheme="dark"
    class="d-print-none sidebar-fixed">

    <div class="sidebar-brand">
      <CIcon name="cilShieldAlt" size="lg" class="brand-icon" />
      <span v-if="!sidebarNarrow" class="brand-text">Admin Panel</span>
    </div>

    <CSidebarNav>
      <CNavItem href="#/admin/dashboard">
        <CIcon customClassName="nav-icon" name="cilSpeedometer" />
        Dashboard
      </CNavItem>

      <CNavGroup>
        <template #togglerContent>
          <CIcon customClassName="nav-icon" name="cilPeople" />
          User Management
        </template>
        <CNavItem href="#/admin/users">All Users</CNavItem>
        <CNavItem href="#/admin/clients">Companies</CNavItem>
        <CNavItem href="#/admin/invitations">Invitations</CNavItem>
      </CNavGroup>

      <CNavGroup>
        <template #togglerContent>
          <CIcon customClassName="nav-icon" name="cilSettings" />
          System
        </template>
        <CNavItem href="#/admin/system-settings">Settings</CNavItem>
        <CNavItem href="#/admin/logs">Logs</CNavItem>
        <CNavItem href="#/admin/maintenance">Maintenance</CNavItem>
      </CNavGroup>

      <CNavItem href="#/admin/analytics">
        <CIcon customClassName="nav-icon" name="cilBarChart" />
        System Analytics
      </CNavItem>
    </CSidebarNav>
  </CSidebar>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import useStore from '@/stores';

  const store = useStore();
  const sidebarNarrow = computed(() => store.$state.sidebarNarrow);
  const sidebarVisible = computed(() => store.$state.sidebarVisible);
</script>

<style scoped>
  .full-height-sidebar {
    height: 100vh;
    position: fixed;
    left: 0;
    top: 0;
    z-index: 1000;
  }

  .sidebar-brand {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 1rem;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    background-color: rgba(220, 38, 38, 0.2); /* Admin red theme */
    min-height: 60px;
  }

  .brand-icon {
    color: #fecaca; /* Light red for admin */
    flex-shrink: 0;
  }

  .brand-text {
    color: #fecaca;
    font-size: 1.25rem;
    font-weight: 600;
    margin-left: 0.5rem;
    white-space: nowrap;
  }

  .sidebar-toggler {
    margin: 0.5rem auto;
    margin-bottom: 1rem;
    display: block;
    color: #fff;
    cursor: pointer;
    padding: 0.5rem;
    border-radius: 0.375rem;
    transition: background-color 0.15s ease-in-out;
  }

  .sidebar-toggler:hover {
    background-color: rgba(255, 255, 255, 0.1);
}
</style>
