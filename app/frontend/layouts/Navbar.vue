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
    </CContainer>
  </CHeader>
</template>

<script lang="ts" setup>
  import { ref, computed } from 'vue';
  import useAuth from '@/composables/useAuth';
  import AccountDropdown from '@/components/AccountDropdown.vue';

  const { user, paths, features, sites } = useAuth();

  const selectedSite = ref<number | null>(null);

  const selectedSiteName = computed(() => {
    if (!selectedSite.value || !sites.value) return null;
    const site = sites.value.find(s => s.id === selectedSite.value);
    return site?.name || null;
  });

  const onSelectSite = (siteId: number | null) => {
    selectedSite.value = siteId;
  };

  const onAddSite = () => {
    console.log('Add new site clicked');
    // Implement your add site logic here
    // This could navigate to a form or open a modal
  };
</script>

<style scoped>
</style>
