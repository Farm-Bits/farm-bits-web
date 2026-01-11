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
              {{ site?.name || 'No Sites Configured' }}
            </CDropdownToggle>
            <CDropdownMenu>
              <template v-if="sites && sites.length > 0">
                <CDropdownItem
                  v-for="otherSite in sites"
                  :key="otherSite.id"
                  @click="onSelectSite(otherSite.id)"
                  :active="site?.id === otherSite.id">
                  {{ otherSite.name }}
                </CDropdownItem>
                <CDropdownDivider />
                <CDropdownItem
                  v-if="permissions.sites.index"
                  class="d-flex align-items-center text-primary"
                  @click="router.visit(ROUTES.sites_index.path)">
                  <CIcon name="cilCompress" class="me-2" />
                  Manage Sites
                </CDropdownItem>
              </template>
              <template v-else>
                <CDropdownDivider />
                <CDropdownItem
                  v-if="permissions.sites.index"
                  class="d-flex align-items-center text-primary"
                  @click="router.visit(ROUTES.sites_index.path)">
                  <CIcon name="cilCompress" class="me-2" />
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
            <Link class="nav-link text-secondary-light" :href="paths.pages.signIn">
              Sign In
            </Link>
          </CNavItem>
          <CNavItem v-if="features.canRegister">
            <Link class="nav-link text-secondary-light" :href="paths.pages.signUp">
              Sign Up
            </Link>
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
  import { router } from '@inertiajs/vue3';
  import AccountDropdown from './components/AccountDropdown.vue';
  import AdminAccountDropdown from './components/AdminAccountDropdown.vue';
  import useAuth from '@/composables/useAuth';
  import usePermissions from '@/composables/usePermissions';
  import type { Site } from '@/types/location';
  import { ROUTES } from '@/types/permissions';

  const { isAdminUser, isSignedIn, paths, features, site, sites } = useAuth();
  const { permissions } = usePermissions();

  function onSelectSite(siteId: Site['id']) {
    router.visit(window.location.pathname, { data: { site_id: siteId } });
  }
</script>

<style scoped>
</style>
