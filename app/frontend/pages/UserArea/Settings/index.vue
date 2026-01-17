<template>
  <CCardHeader>
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
      <CTabContent>
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
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import ClientTab from './components/tabs/ClientTab.vue';
  import UsersTab from './components/tabs/UsersTab.vue';
  import DangerTab from './components/tabs/DangerTab.vue';

  const activeTab = ref('client');
</script>

<style scoped>
</style>
