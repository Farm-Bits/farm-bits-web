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
              {{ currentSite?.name || 'No Sites Configured' }}
            </CDropdownToggle>
            <CDropdownMenu>
              <template v-if="accessibleSites && accessibleSites.length > 0">
                <CDropdownItem
                  v-for="site in accessibleSites"
                  :key="site.id"
                  @click="onSelectSite(site.id)"
                  :active="currentSite?.id === site.id">
                  {{ site.name }}
                </CDropdownItem>
              </template>
              <template v-else>
                <CDropdownItem disabled>
                  No Sites Available
                </CDropdownItem>
              </template>
            </CDropdownMenu>
          </CDropdown>
        </template>
      </div>

      <!-- Center: Weather & Sun data (only for regular users with a site) -->
      <div v-if="isSignedIn && !isAdminUser" class="d-none d-lg-flex align-items-center">
        <WeatherNavBar />
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
          <!-- Regular users get the full company-switching dropdown -->
          <AccountDropdown v-else />
        </template>
      </CHeaderNav>
    </CContainer>
  </CHeader>
</template>

<script lang="ts" setup>
  import { router } from '@inertiajs/vue3';
  import WeatherNavBar from './components/WeatherNavBar.vue';
  import AccountDropdown from './components/AccountDropdown.vue';
  import AdminAccountDropdown from './components/AdminAccountDropdown.vue';
  import useAuth from '@/composables/useAuth';
  import type { Site } from '@/types/location';

  const { isAdminUser, isSignedIn, paths, features, currentSite, accessibleSites } = useAuth();

  function onSelectSite(siteId: Site['id']) {
    router.visit(window.location.pathname, { data: { site_id: siteId } });
  }
</script>

<style scoped>
</style>
