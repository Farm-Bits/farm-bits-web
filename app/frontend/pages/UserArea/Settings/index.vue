<template>
  <div class="container-fluid py-4">
    <CRow class="mb-4">
      <CCol>
        <h1 class="mb-1">Company Settings</h1>
        <p class="text-muted mb-0">Manage your company profile, users, and sites</p>
      </CCol>
    </CRow>

    <CCardHeader>
      <CTabs v-model:active-item-key="activeTab" variant="tabs">
        <CTabList variant="tabs">
          <CTab
            v-if="permissions?.client_setup.edit"
            item-key="company"
            class="tab-item">
            <CIcon name="cilBuilding" class="me-2" />
            Company Information
          </CTab>

          <CTab
            v-if="permissions?.client_users.index"
            item-key="users"
            class="tab-item">
            <CIcon name="cilPeople" class="me-2" />
            Users
          </CTab>

          <CTab
            v-if="permissions?.sites.index"
            item-key="sites"
            class="tab-item">
            <CIcon name="cilLocationPin" class="me-2" />
            Sites
          </CTab>

          <CTab
            v-if="permissions?.client_setup.destroy"
            item-key="danger"
            class="tab-item tab-danger">
            <CIcon name="cilWarning" class="me-2" />
            Danger Zone
          </CTab>
        </CTabList>

        <!-- Tab Content -->
        <CTabContent>
          <CTabPanel v-if="permissions?.client_setup.edit" item-key="company">
            <ClientTab />
          </CTabPanel>

          <CTabPanel v-if="permissions?.client_users.index" item-key="users">
            <UsersTab />
          </CTabPanel>

          <CTabPanel v-if="permissions?.sites.index" item-key="sites">
            <SitesTab />
          </CTabPanel>

          <CTabPanel v-if="permissions?.client_setup.destroy" item-key="danger">
            <DangerTab />
          </CTabPanel>
        </CTabContent>
      </CTabs>
    </CCardHeader>
  </div>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import ClientTab from './components/tabs/ClientTab.vue';
  import UsersTab from './components/tabs/UsersTab.vue';
  import SitesTab from './components/tabs/SitesTab.vue';
  import DangerTab from './components/tabs/DangerTab.vue';
  import usePermissions from '@/composables/usePermissions';

  const { permissions } = usePermissions();
  const activeTab = ref('company');
</script>

<style scoped>
  .tab-danger {
    color: #dc3545;
  }

  .tab-danger:hover {
    color: #bb2d3b;
  }
</style>
