<template>
  <AdminSidebar v-if="isAdminUser" />
  <UserSidebar v-else-if="isSignedIn" />
</template>

<script lang="ts" setup>
  import useAuth from '@/composables/useAuth';
  import AdminSidebar from './components/AdminSidebar.vue';
  import UserSidebar from './components/UserSidebar.vue';

  const { isAdminUser, isSignedIn } = useAuth();
</script>

<style scoped>
</style>
