<template>
  <CContainer fluid class="px-4 py-4">
    <CRow class="mb-4">
      <CCol>
        <h1 class="mb-1">My Account</h1>
        <p class="text-muted mb-0">Manage your profile, password, security, and account preferences</p>
      </CCol>
    </CRow>

    <CTabs v-model:active-item-key="activeTab" variant="tabs">
      <CTabList variant="tabs">
        <CTab
          v-if="permissions?.my_account.show"
          item-key="profile"
          class="tab-item">
          <CIcon name="cilUser" class="me-2" />
          Profile
        </CTab>

        <CTab
          v-if="permissions?.my_account.update"
          item-key="password"
          class="tab-item">
          <CIcon name="cilLockLocked" class="me-2" />
          Password
        </CTab>

        <CTab
          v-if="permissions?.two_factors.update"
          item-key="security"
          class="tab-item">
          <CIcon name="cilShieldAlt" class="me-2" />
          Security
        </CTab>

        <CTab
          v-if="permissions?.my_account.destroy"
          item-key="danger"
          class="tab-item tab-danger">
          <CIcon name="cilWarning" class="me-2" />
          Danger Zone
        </CTab>
      </CTabList>

      <CTabContent>
        <CTabPanel v-if="permissions?.my_account.show" item-key="profile">
          <ProfileTab />
        </CTabPanel>

        <CTabPanel v-if="permissions?.my_account.update" item-key="password">
          <PasswordTab />
        </CTabPanel>

        <CTabPanel v-if="permissions?.two_factors.update" item-key="security">
          <SecurityTab />
        </CTabPanel>

        <CTabPanel v-if="permissions?.my_account.destroy" item-key="danger">
          <DangerTab />
        </CTabPanel>
      </CTabContent>
    </CTabs>
  </CContainer>
</template>

<script lang="ts" setup>
  import { onMounted, ref, watch } from 'vue';
  import ProfileTab from './tabs/ProfileTab.vue';
  import PasswordTab from './tabs/PasswordTab.vue';
  import SecurityTab from './tabs/SecurityTab.vue';
  import DangerTab from './tabs/DangerTab.vue';
  import usePermissions from '@/composables/usePermissions';

  type ProfileTabKey = 'profile' | 'password' | 'security' | 'danger';
  const TAB_KEYS: readonly ProfileTabKey[] = ['profile', 'password', 'security', 'danger'] as const;

  const { permissions } = usePermissions();
  const activeTab = ref<ProfileTabKey>('profile');

  function isTabKey(value: string | null): value is ProfileTabKey {
    return value !== null && (TAB_KEYS as readonly string[]).includes(value);
  }

  // Read tab from URL on mount so redirects (e.g. from two_factor#update with
  // a ?tab=security param) land on the right tab. Devise/Inertia redirects
  // re-render this page from scratch, so this is the only reliable source.
  onMounted(() => {
    const params = new URLSearchParams(window.location.search);
    const tab = params.get('tab');
    if (isTabKey(tab))
      activeTab.value = tab;
  });

  watch(activeTab, (newTab) => {
    const url = new URL(window.location.href);
    url.searchParams.set('tab', newTab);
    window.history.replaceState({}, '', url.toString());
  });
</script>

<style scoped>
  .tab-danger {
    color: #dc3545;
  }

  .tab-danger:hover {
    color: #bb2d3b;
  }
</style>
