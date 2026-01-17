<template>
  <div class="dropdown">
    <button
      class="btn btn-link nav-link py-2 px-0 px-lg-2 d-flex align-items-center"
      type="button"
      @click="toggleDropdown"
      ref="dropdownToggle">
      <CAvatar v-if="currentClient" size="md" :style="{ backgroundColor: currentClient.color }">
        {{ getInitials(currentClient.name) }}
      </CAvatar>
      <CAvatar v-else size="md">
        {{ getInitials(pageProps.user.name) }}
      </CAvatar>
    </button>

    <div
      :class="['dropdown-menu', 'dropdown-menu-end', { show: isOpen }]"
      ref="dropdownMenu">
      <div class="dropdown-container" :style="containerStyle">
        <!-- Default Menu Panel -->
        <div class="dropdown-panel">
          <div class="dropdown-header d-flex align-items-center mb-2">
              <CAvatar v-if="currentClient" size="sm" :style="{ backgroundColor: currentClient.color }" class="me-2">
                {{ getInitials(pageProps.user.name) }}
              </CAvatar>
              <div class="user-info">
                <div class="fw-semibold">{{ pageProps.user.name }}</div>
                <small v-if="currentClient" class="text-muted">{{ currentClient.name }}</small>
              </div>
            </div>

          <CDropdownDivider />

          <CDropdownHeader>Account</CDropdownHeader>

          <CDropdownItem
            class="d-flex align-items-center"
            @click="visit(paths.pages.myAccount)">
            <CIcon icon="cilUser" class="me-2" />
            Profile
          </CDropdownItem>

          <CDropdownItem
            v-if="permissions?.client_setup.edit"
            class="d-flex align-items-center"
            @click="visit(paths.pages.editClient)">
            <CIcon icon="cilSettings" class="me-2" />
            Settings
          </CDropdownItem>

          <CDropdownItem
            v-if="isClientConnected"
            @click="showClientPanel"
            class="d-flex align-items-center justify-content-between">
            <div class="d-flex align-items-center">
              <CIcon icon="cilPeople" class="me-2" />
              Switch Company
            </div>
            <CIcon icon="cilArrowRight" size="sm" />
          </CDropdownItem>

          <CDropdownDivider />

          <CDropdownItem
            class="d-flex align-items-center text-danger cursor-pointer"
            @click="router.delete(paths.actions.signOut)">
            <CIcon icon="cilAccountLogout" class="me-2" />
            Sign Out
          </CDropdownItem>
        </div>

        <!-- Clients Panel -->
        <div v-if="isClientConnected" class="dropdown-panel">
          <div class="dropdown-header d-flex align-items-center">
            <button
              @click="showDefaultPanel"
              class="btn btn-link p-0 me-2 text-decoration-none"
              style="color: var(--cui-body-color);">
              <CIcon icon="cilArrowLeft" />
            </button>
            <span class="fw-semibold">Switch Company</span>
          </div>

          <div v-if="currentClient" class="current-client mb-2">
            <small class="text-muted">Current Company</small>
            <CDropdownItem class="active d-flex align-items-center">
              <div
                class="client-avatar me-2"
                :style="{ backgroundColor: currentClient.color }">
                {{ getInitials(currentClient.name) }}
              </div>
              {{ currentClient.name }}
              <CIcon icon="cilCheckAlt" class="ms-auto text-success" size="sm" />
            </CDropdownItem>
          </div>

          <div v-if="otherClients.length > 0">
            <CDropdownDivider />
            <div class="other-clients">
              <small class="text-muted px-3">Other Companies</small>
              <CDropdownItem
                v-for="otherClient in otherClients"
                :key="otherClient.id"
                class="d-flex align-items-center"
                @click="visit(pathname, { data: { client_id: otherClient.id } })">
                <div
                  class="client-avatar me-2"
                  :style="{ backgroundColor: otherClient.color }">
                  {{ getInitials(otherClient.name) }}
                </div>
                {{ otherClient.name }}
              </CDropdownItem>
            </div>
          </div>

          <CDropdownDivider />
          <CDropdownItem class="d-flex align-items-center" @click="visit(paths.pages.newClient)">
            <CIcon icon="cilPlus" class="me-2" />
            Create New Company
          </CDropdownItem>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { ref, reactive, computed, onMounted, onUnmounted } from 'vue';
  import { router } from '@inertiajs/vue3';
  import useAuth from '@/composables/useAuth';
  import usePermissions from '@/composables/usePermissions';
  import { type User } from '@/types/inertia';

  const { pageProps, userScope, paths, client, clients } = useAuth<{
    user: User;
  }>();
  const { permissions } = usePermissions();

  const pathname = window.location.pathname;

  const isOpen = ref(false);
  const currentPanel = ref<'default' | 'clients'>('default');
  const dropdownToggle = ref<HTMLElement | null>(null);
  const dropdownMenu = ref<HTMLElement | null>(null);

  const isClientConnected = computed(() => userScope.value !== 'admin_users');

  const currentClient = reactive(client);
  const otherClients = computed(() =>
    clients.value.filter((c) => c.id !== currentClient.value?.id)
  );

  const containerStyle = computed(() => ({
    transform: `translateX(${currentPanel.value === 'clients' ? '-50%' : '0%'})`,
    transition: 'transform 0.3s cubic-bezier(0.4, 0, 0.2, 1)'
  }));

  function toggleDropdown() {
    isOpen.value = !isOpen.value;
    if (!isOpen.value) {
      setTimeout(() => {
        currentPanel.value = 'default';
      }, 150);
    }
  }

  function getInitials(name: string) {
    return (name.match(/\b\w/g) || []).join('').toUpperCase();
  }

  function showClientPanel() {
    currentPanel.value = 'clients';
  }

  function showDefaultPanel() {
    currentPanel.value = 'default';
  }

  function handleClickOutside(event: MouseEvent) {
    if (
      dropdownToggle.value &&
      dropdownMenu.value &&
      !dropdownToggle.value.contains(event.target as Node) &&
      !dropdownMenu.value.contains(event.target as Node)
    ) {
      isOpen.value = false
      setTimeout(() => {
        currentPanel.value = 'default'
      }, 150)
    }
  }

  function visit(path: string, options: Record<string, any> = {}) {
    isOpen.value = false;
    currentPanel.value = 'default';
    router.visit(path, options);
  }

  onMounted(() => {
    document.addEventListener('click', handleClickOutside)
  });

  onUnmounted(() => {
    document.removeEventListener('click', handleClickOutside)
  });
</script>

<style scoped>
  .dropdown-menu {
    position: absolute;
    top: 100%;
    right: 0;
    z-index: 1000;
    width: 220px;
    padding: 0;
    overflow: hidden;
    border: 1px solid var(--cui-border-color);
    border-radius: 0.375rem;
    background-color: var(--cui-dropdown-bg);
    box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15);
    transform: translateY(0.5rem);
  }

  .dropdown-container {
    display: flex;
    width: 200%;
    will-change: transform;
  }

  .dropdown-panel {
    width: 50%;
    padding-bottom: 0.5rem;
    flex-shrink: 0;
  }

  .client-avatar {
    width: 24px;
    height: 24px;
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-size: 10px;
    font-weight: 600;
    flex-shrink: 0;
  }

  .current-client {
    padding: 0 1rem;
  }

  .other-clients small {
    display: block;
    padding: 0.5rem 0 0.25rem 0;
    font-weight: 500;
  }

  .btn-link {
    border: none;
    background: none;
    text-decoration: none;
    font-size: inherit;
  }

  .btn-link:hover {
    text-decoration: none;
    color: var(--cui-danger) !important;
  }
</style>
