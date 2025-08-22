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
                <UsersTab />
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

  const activeTab = ref('client');
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
