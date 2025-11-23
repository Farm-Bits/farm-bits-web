<template>
  <CHeader position="sticky">
    <CContainer fluid class="px-4">
      <!-- Left side: Logo/Brand or Site Selection -->
      <div class="d-flex align-items-center">
        <!-- Admin User: Just logo/brand -->
        <template v-if="isAdminUser">
          <CNavbarBrand class="d-flex align-items-center">
            <CIcon name="cilGem" class="me-2" />
            <span class="fw-bold">Farm Bits Admin</span>
          </CNavbarBrand>
        </template>

        <!-- Regular User: Site selection -->
        <template v-else-if="isSignedIn">
          <CDropdown variant="nav-item">
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
                <CDropdownItem
                  v-if="permissions.sites.create"
                  @click="onAddSite"
                  class="d-flex align-items-center text-primary">
                  <CIcon name="cilPlus" class="me-2" />
                  Add New Site
                </CDropdownItem>
              </template>
              <template v-else>
                <CDropdownDivider />
                <CDropdownItem
                  v-if="permissions.sites.create"
                  @click="onAddSite"
                  class="d-flex align-items-center text-primary">
                  <CIcon name="cilPlus" class="me-2" />
                  Add Your First Site
                </CDropdownItem>
              </template>
            </CDropdownMenu>
          </CDropdown>
        </template>
      </div>

      <!-- Right side navigation -->
      <CHeaderNav class="d-none d-md-flex ms-auto align-items-center">
        <!-- Not logged in: Sign In/Sign Up buttons -->
        <template v-if="!isSignedIn">
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
          <!-- Admin users get a simpler dropdown -->
          <AdminAccountDropdown v-if="isAdminUser" />
          <!-- Regular users get the full client-switching dropdown -->
          <AccountDropdown v-else />
        </template>
      </CHeaderNav>
    </CContainer>
  </CHeader>
</template>

<script lang="ts" setup>
  import { ref, computed } from 'vue';
  import useAuth from '@/composables/useAuth';
  import usePermissions from '@/composables/usePermissions';
  import AccountDropdown from './components/AccountDropdown.vue';
  import AdminAccountDropdown from './components/AdminAccountDropdown.vue';

  const { isAdminUser, isSignedIn, paths, features, sites } = useAuth();
  const { permissions } = usePermissions();

  const selectedSite = ref<number | null>(null);

  const selectedSiteName = computed(() => {
    if (!selectedSite.value || !sites.value) return null;
    const site = sites.value.find(s => s.id === selectedSite.value);
    return site?.name || null;
  });

  const onSelectSite = (siteId: number | null) => {
    selectedSite.value = siteId;
    // Emit event or call method to update parent component
  };

  const onAddSite = () => {
    console.log('Add new site clicked');
    // Navigate to site creation form
  };
</script>


<style scoped>
</style>
