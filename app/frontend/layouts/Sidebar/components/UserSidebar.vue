<template>
  <CSidebar
    :narrow="sidebarNarrow"
    :visible="sidebarVisible"
    @visible-change="store.setSidebarVisible"
    minimizer
    colorScheme="dark"
    class="d-print-none sidebar-fixed">

    <div class="sidebar-brand">
      <CIcon name="cilGem" size="lg" class="brand-icon" />
      <span v-if="!sidebarNarrow" class="brand-text">Farm Bits</span>
    </div>

    <CSidebarNav>
      <CNavItem v-if="permissions?.live.show">
        <Link :href="routePath('live_show')" :class="['nav-link', { active: isActive(['live']) }]">
          <CIcon customClassName="nav-icon" name="cilRss" />
          Live Data
        </Link>
      </CNavItem>

      <CNavItem v-if="permissions?.alerts.show">
        <Link :href="routePath('alerts_index')" :class="['nav-link', { active: isActive(['alerts', 'alert_rules']) }]">
          <CIcon customClassName="nav-icon" name="cilBellExclamation" />
          Alerts
          <CBadge v-if="openAlertCount > 0" color="danger" class="ms-auto">
            {{ openAlertCount }}
          </CBadge>
        </Link>
      </CNavItem>

      <CNavItem v-if="permissions?.programs.index">
        <Link :href="routePath('programs_index')" :class="['nav-link', { active: isActive(['programs']) }]">
          <CIcon customClassName="nav-icon" name="cilList" />
          Programs
        </Link>
      </CNavItem>

      <CNavItem v-if="permissions?.analytics.show">
        <Link :href="routePath('analytics_show')" :class="['nav-link', { active: isActive(['analytics']) }]">
          <CIcon customClassName="nav-icon" name="cilBarChart" />
          Analytics
        </Link>
      </CNavItem>

      <CNavItem v-if="permissions?.devices.index">
        <Link :href="routePath('devices_index')" :class="['nav-link', { active: isActive(['devices', 'plcs', 'modbus_devices', 'gateways', 'measurement_points']) }]">
          <CIcon customClassName="nav-icon" name="cilSpeedometer" />
          Devices
        </Link>
      </CNavItem>
    </CSidebarNav>
  </CSidebar>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import useAuth from '@/composables/useAuth';
  import usePermissions from '@/composables/usePermissions';
  import useStore from '@/stores';

  const { openAlertCount, routePath, currentController } = useAuth();
  const { permissions } = usePermissions();
  const store = useStore();

  const sidebarNarrow = computed(() => store.$state.sidebarNarrow);
  const sidebarVisible = computed(() => store.$state.sidebarVisible);

  function isActive(controllers: string[]): boolean {
    return !!currentController.value && controllers.includes(currentController.value);
  }
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
