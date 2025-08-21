<template>
  <div class="app">
    <!-- Main content area -->
    <div class="body">
      <Sidebar />
      <!-- Main content -->
      <div class="main">
        <Navbar />

        <!-- Toast notifications -->
        <CToaster class="right-4 fixed">
          <CToast v-for="(toast, index) in toasts" visible :key="index" :autohide="false">
            <CToastHeader closeButton>
              <span class="me-auto fw-bold">
                {{ toast.title }}
              </span>
            </CToastHeader>
            <CToastBody>
              {{ toast.message }}
            </CToastBody>
          </CToast>
        </CToaster>

        <!-- Page content slot -->
        <div class="content">
          <div v-if="flash.alert" class="alert">
            {{ flash.alert }}
          </div>
          <div v-if="flash.notice" class="notice">
            {{ flash.notice }}
          </div>
          <slot />
        </div>
      </div>
    </div>

    <!-- Footer -->
    <Footer />
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import Navbar from './Navbar.vue';
  import Sidebar from './Sidebar.vue';
  import Footer from './Footer.vue';
  import { usePage } from '@inertiajs/vue3';
  import useToastStore from '@/stores/toast';

  const page = usePage<{
    flash: {
      alert?: string;
      notice?: string;
    };
  }>();
  const flash = computed(() => page.props.flash);

  const { toasts } = useToastStore();
</script>

<style scoped>
  .app {
    display: flex;
    flex-direction: column;
    min-height: 100vh;
  }

  .body {
    display: flex;
    flex-direction: row;
    flex: 1;
  }

  .main {
    flex: 1;
    display: flex;
    flex-direction: column;
  }

  .content {
    flex: 1;
  }
</style>