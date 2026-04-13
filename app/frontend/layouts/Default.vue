<template>
  <div class="app">
    <!-- Main content area -->
    <div class="body">
      <Sidebar />
      <!-- Main content -->
      <div class="main" :style="{ marginLeft: sidebarOffset }">
        <Navbar />

        <!-- Toast notifications -->
        <CToaster class="right-4 fixed">
          <CToast v-for="(toast, index) in toasts" visible :key="index">
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
          <!-- Flash notifications with close functionality -->
          <div
            v-for="(value, key) in visibleFlash"
            class="flash-notification"
            :key="key"
            :class="[key, 'flash-notification']">
            {{ value }}
            <button
              class="btn-close"
              aria-label="Close"
              @click="closeFlashNotification(key)">
              &times;
            </button>
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
  import { computed, ref } from 'vue';
  import Navbar from './Navbar/index.vue';
  import Sidebar from './Sidebar/index.vue';
  import Footer from './Footer.vue';
  import { usePage } from '@inertiajs/vue3';
  import useAuth from '@/composables/useAuth';
  import useStore from '@/stores';
  import useToastStore from '@/stores/toast';

  const page = usePage<{
    flash: {
      alert?: string;
      notice?: string;
      [key: string]: any;
    };
  }>();

  const { isAdminUser, isSignedIn } = useAuth();
  const store = useStore();

  const sidebarOffset = computed(() => {
    if (!isAdminUser.value && !isSignedIn.value)
      return '0px';

    if (!store.sidebarVisible)
      return '0px';

    return store.sidebarNarrow ? '56px' : '256px';
  });

  const dismissedFlash = ref<Set<string>>(new Set());

  const flash = computed(() => page.props.flash);
  const visibleFlash = computed(() => {
    const filtered: Record<string, string> = {};

    for (const [key, value] of Object.entries(flash.value)) {
      if (value && !dismissedFlash.value.has(key))
        filtered[key] = value;
    }

    return filtered;
  });

  const { toasts } = useToastStore();

  function closeFlashNotification(flashKey: string) {
    dismissedFlash.value.add(flashKey);
  }
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

  .flash-notification {
    position: relative;
    padding: 12px 40px 12px 16px;
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  /* Different styles for different flash types */
  .flash-notification.alert {
    background-color: #f8d7da;
    color: #721c24;
    border: 1px solid #f5c6cb;
  }

  .flash-notification.notice {
    background-color: #d4edda;
    color: #155724;
    border: 1px solid #c3e6cb;
  }

  .flash-notification.warning {
    background-color: #fff3cd;
    color: #856404;
    border: 1px solid #ffeaa7;
  }

  /* Close button styling */
  .btn-close {
    position: absolute;
    top: 50%;
    right: 12px;
    transform: translateY(-50%);
    background: none;
    border: none;
    font-size: 20px;
    cursor: pointer;
    color: inherit;
    opacity: 0.7;
    padding: 0;
    width: 20px;
    height: 20px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .btn-close:hover {
    opacity: 1;
  }

  /* Animation for smooth removal */
  .flash-notification {
    transition: all 0.3s ease-out;
  }
</style>