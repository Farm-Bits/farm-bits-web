<template>
  <CHeader position="sticky">
    <CContainer fluid class="px-4">
      <!-- Site selection dropdown - moved to start -->
      <template v-if="user">
        <CDropdown variant="nav-item" class="me-auto">
          <CDropdownToggle class="d-flex align-items-center">
            <CIcon name="cilLocationPin" class="me-1" />
            {{ selectedSiteName || 'All Sites' }}
          </CDropdownToggle>
          <CDropdownMenu>
            <CDropdownItem @click="onSelectSite(null)" :active="selectedSite === null">
              All Sites
            </CDropdownItem>
            <template v-if="sites && sites.length > 0">
              <CDropdownDivider />
              <CDropdownItem
                v-for="site in sites"
                :key="site.id"
                @click="onSelectSite(site.id)"
                :active="selectedSite === site.id">
                {{ site.name }}
              </CDropdownItem>
              <CDropdownDivider />
              <CDropdownItem @click="onAddSite" class="d-flex align-items-center text-primary">
                <CIcon name="cilPlus" class="me-2" />
                Add New Site
              </CDropdownItem>
            </template>
            <template v-else>
              <CDropdownDivider />
              <CDropdownItem @click="onAddSite" class="d-flex align-items-center text-primary">
                <CIcon name="cilPlus" class="me-2" />
                Add Your First Site
              </CDropdownItem>
            </template>
          </CDropdownMenu>
        </CDropdown>
      </template>

      <!-- Mobile menu toggle -->
      <CHeaderToggler
        class="d-md-none ms-auto"
        @click="toggleMobileMenu"
        :aria-expanded="mobileMenuOpen">
        <CIcon name="cilMenu" />
      </CHeaderToggler>

      <!-- Right side navigation -->
      <CHeaderNav class="d-none d-md-flex ms-auto align-items-center">
        <!-- Not logged in: Sign In/Sign Up buttons -->
        <template v-if="!user">
          <CNavItem>
            <CNavLink :href="paths.pages.signIn" class="text-secondary-light">
              Sign In
            </CNavLink>
          </CNavItem>
          <CNavItem v-if="features.canRegister">
            <CNavLink :href="paths.pages.signUp" class="text-secondary-light">
              Sign Up
            </CNavLink>
          </CNavItem>
        </template>

        <!-- Logged in: User menu -->
        <template v-else>
          <AccountDropdown />
        </template>
      </CHeaderNav>

      <!-- Mobile Navigation Menu -->
      <CCollapse
        :visible="mobileMenuOpen"
        class="d-md-none w-100 mt-3"
        horizontal="false">
        <CNav variant="pills" layout="vertical" class="border-top pt-3">
          <!-- Not logged in mobile menu -->
          <template v-if="!user">
            <CNavItem>
              <CNavLink :href="paths.pages.signIn" class="text-secondary-light">
                Sign In
              </CNavLink>
            </CNavItem>
            <CNavItem v-if="features.canRegister">
              <CNavLink :href="paths.pages.signUp" class="text-secondary-light">
                Sign Up
              </CNavLink>
            </CNavItem>
          </template>

          <!-- Logged in mobile menu -->
          <template v-else>
            <!-- Site selection in mobile -->
            <CNavItem class="mb-2">
              <div class="fw-semibold text-muted small mb-2">Site Selection</div>
              <CDropdown variant="nav-item">
                <CDropdownToggle class="d-flex align-items-center w-100">
                  <CIcon name="cilLocationPin" class="me-2" />
                  {{ selectedSiteName || 'All Sites' }}
                  <CIcon name="cilChevronBottom" class="ms-auto" />
                </CDropdownToggle>
                <CDropdownMenu>
                  <CDropdownItem @click="onSelectSite(null)" :active="selectedSite === null">
                    All Sites
                  </CDropdownItem>
                  <template v-if="sites && sites.length > 0">
                    <CDropdownDivider />
                    <CDropdownItem
                      v-for="site in sites"
                      :key="site.id"
                      @click="onSelectSite(site.id)"
                      :active="selectedSite === site.id">
                      {{ site.name }}
                    </CDropdownItem>
                    <CDropdownDivider />
                    <CDropdownItem @click="onAddSite" class="d-flex align-items-center text-primary">
                      <CIcon name="cilPlus" class="me-2" />
                      Add New Site
                    </CDropdownItem>
                  </template>
                  <template v-else>
                    <CDropdownDivider />
                    <CDropdownItem @click="onAddSite" class="d-flex align-items-center text-primary">
                      <CIcon name="cilPlus" class="me-2" />
                      Add Your First Site
                    </CDropdownItem>
                  </template>
                </CDropdownMenu>
              </CDropdown>
            </CNavItem>

            <!-- Mobile user menu items -->
            <CNavItem class="mb-2">
              <div class="fw-semibold text-muted small mb-2">Account</div>
              <CNavLink href="#" class="d-flex align-items-center">
                <CIcon name="cilUser" class="me-2" />
                Profile
              </CNavLink>
            </CNavItem>

            <CNavItem class="mb-2">
              <CNavLink href="#" class="d-flex align-items-center">
                <CIcon name="cilSettings" class="me-2" />
                Settings
              </CNavLink>
            </CNavItem>

            <!-- Company switching in mobile (if applicable) -->
            <CNavItem v-if="isClientConnected" class="mb-2">
              <CNavLink @click="showMobileClientPanel" class="d-flex align-items-center">
                <CIcon name="cilPeople" class="me-2" />
                Switch Company
              </CNavLink>
            </CNavItem>

            <!-- Sign out in mobile -->
            <CNavItem>
              <form :action="paths.actions.signOut" method="post" class="w-100">
                <input type="hidden" name="_method" value="delete">
                <button
                  type="submit"
                  class="btn btn-link nav-link w-100 text-start d-flex align-items-center text-danger p-2">
                  <CIcon name="cilAccountLogout" class="me-2" />
                  Sign Out
                </button>
              </form>
            </CNavItem>
          </template>
        </CNav>
      </CCollapse>
    </CContainer>
  </CHeader>
</template>

<script lang="ts" setup>
  import { ref, computed } from 'vue';
  import useAuth from '@/composables/useAuth';
  import AccountDropdown from '@/components/AccountDropdown.vue';

  const { user, paths, features, sites, userScope } = useAuth();

  const selectedSite = ref<number | null>(null);
  const mobileMenuOpen = ref(false);

  const isClientConnected = computed(() => userScope.value !== 'admin_users');

  const selectedSiteName = computed(() => {
    if (!selectedSite.value || !sites.value) return null;
    const site = sites.value.find(s => s.id === selectedSite.value);
    return site?.name || null;
  });

  const toggleMobileMenu = () => {
    mobileMenuOpen.value = !mobileMenuOpen.value;
  };

  const onSelectSite = (siteId: number | null) => {
    selectedSite.value = siteId;
    mobileMenuOpen.value = false; // Close mobile menu when selecting
  };

  const onAddSite = () => {
    console.log('Add new site clicked');
    // Implement your add site logic here
    // This could navigate to a form or open a modal
    mobileMenuOpen.value = false; // Close mobile menu
  };

  const showMobileClientPanel = () => {
    console.log('Show mobile client panel');
    // Implement mobile client switching logic
    mobileMenuOpen.value = false;
  };
</script>

<style scoped>
  /* Mobile menu styles */
  .collapse.show {
    border-top: 1px solid var(--cui-border-color);
  }

  /* Mobile nav styling */
  .nav-pills .nav-link {
    border-radius: 0.375rem;
    padding: 0.5rem 0.75rem;
  }

  .nav-pills .nav-link:hover {
    background-color: var(--cui-primary-bg-subtle);
  }

  /* Mobile sign out button styling */
  .btn-link.nav-link {
    border: none;
    background: none;
    text-decoration: none;
  }

  .btn-link.nav-link:hover {
    background-color: var(--cui-danger-bg-subtle);
  }

  /* Mobile responsiveness */
  @media (max-width: 767.98px) {
    .header {
      margin-left: 0;
    }

    .dropdown-menu {
      position: static !important;
      transform: none !important;
      box-shadow: none;
      border: 1px solid var(--cui-border-color);
      border-radius: 0.375rem;
      margin-top: 0.5rem;
    }
  }
</style>
