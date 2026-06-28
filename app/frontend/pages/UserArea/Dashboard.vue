<template>
  <CContainer fluid class="p-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <h5 class="mb-1">Dashboard</h5>
        <p class="text-medium-emphasis small mb-0">
          Overview of your sites, devices, and alerts
        </p>
      </div>
    </div>

    <CRow>
      <CCol
        v-for="stat in stats"
        :key="stat.label"
        :sm="6"
        :xl="3"
        class="mb-4">
        <CCard class="h-100 shadow-sm">
          <CCardBody class="d-flex align-items-center">
            <div class="stat-icon bg-light rounded-circle d-flex align-items-center justify-content-center me-3">
              <CIcon :name="stat.icon" size="xl" class="text-medium-emphasis" />
            </div>
            <div>
              <div class="fs-4 fw-semibold lh-1">&mdash;</div>
              <div class="text-medium-emphasis small">{{ stat.label }}</div>
            </div>
          </CCardBody>
        </CCard>
      </CCol>
    </CRow>
  </CContainer>
</template>

<script lang="ts" setup>
  interface DashboardStat {
    label: string;
    icon: string;
  }

  const stats: DashboardStat[] = [
    { label: 'Sites', icon: 'cilBuilding' },
    { label: 'Devices Online', icon: 'cilRouter' },
    { label: 'Active Alerts', icon: 'cilBellExclamation' },
    { label: 'Running Programs', icon: 'cilMediaPlay' }
  ];
</script>

<style scoped>
  .stat-icon {
    width: 3rem;
    height: 3rem;
    flex-shrink: 0;
  }
</style>
