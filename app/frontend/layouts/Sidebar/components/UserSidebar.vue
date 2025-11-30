<template>
  <CSidebar
    :narrow="sidebarNarrow"
    minimizer
    colorScheme="dark"
    class="d-print-none full-height-sidebar">

    <div class="sidebar-brand">
      <CIcon name="cilGem" size="lg" class="brand-icon" />
      <span v-if="!sidebarNarrow" class="brand-text">Farm Bits</span>
    </div>

    <CIcon name="cilMenu" size="lg" @click="store.toggleSidebar" class="sidebar-toggler" />

    <CSidebarNav>
      <CNavItem v-if="permissions.terminals.index">
        <Link :href="ROUTES.terminals_index.path" class="nav-link">
          <CIcon customClassName="nav-icon" name="cilSpeedometer" />
          Devices
        </Link>
      </CNavItem>

      <CNavItem v-if="true" href="#/dashboard">
        <CIcon customClassName="nav-icon" name="cilBarChart" />
        Analytics
      </CNavItem>

      <CNavItem v-if="true" href="#/dashboard">
        <CIcon customClassName="nav-icon" name="cilBellExclamation" />
        Alerts
      </CNavItem>

      <!-- <CNavGroup>
        <template #togglerContent>
          <CIcon customClassName="nav-icon" name="cilPuzzle" />
          Components
        </template>
        <CNavItem href="#/components/buttons">Buttons</CNavItem>
        <CNavItem href="#/components/forms">Forms</CNavItem>
        <CNavItem href="#/components/charts">Charts</CNavItem>
      </CNavGroup> -->
    </CSidebarNav>
  </CSidebar>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import usePermissions from '@/composables/usePermissions';
  import useStore from '@/stores';
  import { ROUTES } from '@/types/permissions';

  const store = useStore();
  const { permissions } = usePermissions();

  const sidebarNarrow = computed(() => store.$state.sidebarNarrow);
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
    background-color: rgba(0, 0, 0, 0.2);
    min-height: 60px;
  }

  .brand-icon {
    color: #fff;
    flex-shrink: 0;
  }

  .brand-text {
    color: #fff;
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
