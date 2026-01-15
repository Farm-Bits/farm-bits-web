<template>
  <div class="container-fluid py-4">
    <!-- Header Section -->
    <CRow class="mb-4">
      <CCol>
        <div class="d-flex justify-content-between align-items-center">
          <div>
            <h1 class="mb-1">Sites</h1>
            <p class="text-muted mb-0">Manage your farm locations and segments</p>
          </div>
          <CButton
            v-if="permissions.sites.create"
            color="primary"
            @click="openCreateModal">
            <CIcon name="cilPlus" class="me-2" />
            Create Site
          </CButton>
        </div>
      </CCol>
    </CRow>

    <!-- Empty State -->
    <div v-if="!sites || sites.length === 0" class="text-center py-5">
      <CIcon icon="cilLocationPin" size="4xl" class="text-muted mb-3" />
      <h4 class="text-muted mb-2">No Sites Yet</h4>
      <p class="text-muted mb-4">
        Get started by creating your first site to monitor and manage your farm locations.
      </p>
      <CButton
        v-if="permissions.sites.update"
        color="primary"
        @click="openCreateModal">
        Create Your First Site
      </CButton>
    </div>

    <!-- Sites Grid -->
    <CRow v-else class="g-4">
      <CCol v-for="site in sites" :key="site.id" class="col-md-3 min-w-sm">
        <CCard class="shadow-sm">
          <CCardHeader class="d-flex justify-content-between bg-white">
            <div class="flex-grow-1">
              <Link
                v-if="permissions.sites.show"
                :href="ROUTES.sites_show.path.replace(':id', String(site.id))">
                <CCardTitle class="nav-link nav-link-secondary !text-lg mb-1">
                  {{ site.name }}
                </CCardTitle>
              </Link>
              <CCardTitle v-else class="mb-1">{{ site.name }}</CCardTitle>
              <small class="text-muted">
                <CIcon name="cilLocationPin" size="sm" class="me-1" />
                {{ formatLocation(site) }}
              </small>
            </div>
            <div
              v-if="permissions.sites.destroy"
              class="d-flex align-items-start gap-2">
              <CDropdown class="options-dropdown">
                <CDropdownToggle color="light" size="sm" :caret="false">
                  <CIcon icon="cilOptions" />
                </CDropdownToggle>
                <CDropdownMenu>
                  <CTooltip :content="sites.length === 1 ? 'You must have at least one site.' : ''" :disabled="sites.length > 1">
                    <template #toggler="{ id, on }">
                      <span v-on="on" class="d-inline-block">
                        <CDropdownItem
                          v-on="on"
                          :class="sites.length > 1 ? 'text-danger' : ''"
                          :disabled="sites.length === 1"
                          @click="confirmDelete(site)">
                          <CIcon icon="cilTrash" class="me-2" />
                          Remove Site
                        </CDropdownItem>
                      </span>
                    </template>
                  </CTooltip>
                </CDropdownMenu>
              </CDropdown>
            </div>
          </CCardHeader>
          <CCardBody class="d-flex flex-column">
            <!-- Site Info Grid -->
            <div class="row g-3 flex-grow-1 mb-3">
              <div class="col-6">
                <small class="text-muted d-block">Time Zone</small>
                <p class="mb-0 small fw-semibold">{{ site.time_zone }}</p>
              </div>
              <div class="col-6">
                <small class="text-muted d-block">Country</small>
                <p class="mb-0 small fw-semibold">{{ site.country }}</p>
              </div>
              <div v-if="site.latitude && site.longitude" class="col-6">
                <small class="text-muted d-block">Coordinates</small>
                <p class="mb-0 small fw-semibold">{{ formatCoordinates(site) }}</p>
              </div>
              <div v-if="site.altitude" class="col-6">
                <small class="text-muted d-block">Altitude</small>
                <p class="mb-0 small fw-semibold">{{ site.altitude }}m</p>
              </div>
            </div>

            <!-- Stats Footer -->
            <div class="row g-2 pt-2 border-top">
              <div class="col-6 d-flex align-items-center gap-2">
                <small class="text-muted">Segments</small>
                <CTooltip :content="getSegmentsName(site.id)">
                  <template #toggler="{ id, on }">
                    <CBadge v-on="on" color="info">
                      {{ getSegmentCount(site.id) }}
                    </CBadge>
                  </template>
                </CTooltip>
              </div>
              <div class="col-6 d-flex align-items-center gap-2">
                <small class="text-muted">Users</small>
                <CTooltip :content="getUsersName(site.id)">
                  <template #toggler="{ id, on }">
                    <CBadge v-on="on" color="secondary">
                      {{ getUserCount(site.id) }}
                    </CBadge>
                  </template>
                </CTooltip>
              </div>
            </div>
          </CCardBody>
        </CCard>
      </CCol>
    </CRow>

    <!-- Site Modal (Create/Edit) -->
    <SiteModal
      :visible="showSiteModal"
      :site="selectedSite"
      @close="closeSiteModal"
      @success="handleSiteSuccess" />

    <!-- Delete Confirmation Modal -->
    <CModal
      :visible="showDeleteModal"
      @close="cancelDelete">
      <CModalHeader>
        <CModalTitle>Confirm Deletion</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <p>Are you sure you want to delete <strong>{{ siteToDelete?.name }}</strong>?</p>
        <p class="text-danger mb-0">
          <CIcon name="cilWarning" class="me-2" />
          This action cannot be undone.
        </p>
      </CModalBody>
      <CModalFooter>
        <CButton
          color="secondary"
          @click="cancelDelete">
          Cancel
        </CButton>
        <CButton
          color="danger"
          :disabled="isDeleting"
          @click="handleDelete">
          <CSpinner v-if="isDeleting" size="sm" class="me-2" />
          {{ isDeleting ? 'Deleting...' : 'Delete' }}
        </CButton>
      </CModalFooter>
    </CModal>
  </div>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import axios from 'axios';
  import SiteModal from './components/SiteModal.vue';
  import useAuth from '@/composables/useAuth';
  import usePermissions from '@/composables/usePermissions';
  import { useApiCall } from '@/composables/useApi';
  import type { Segment, Site, SiteUser } from '@/types/location';
  import { ROUTES } from '@/types/permissions';

  const { site, sites, pageProps } = useAuth<{
    segments: Segment[];
    siteUsers: SiteUser[];
  }>();
  const { permissions } = usePermissions();
  const { execute } = useApiCall();

  const showSiteModal = ref(false);
  const selectedSite = ref<Site | null>(null);
  const showDeleteModal = ref(false);
  const siteToDelete = ref<Site | null>(null);
  const isDeleting = ref(false);

  function openCreateModal() {
    selectedSite.value = null;
    showSiteModal.value = true;
  }

  function closeSiteModal() {
    showSiteModal.value = false;
    selectedSite.value = null;
  }

  function handleSiteSuccess(site: Site) {
    if (!sites.value)
      return;

    if (selectedSite.value) {
      const index = sites.value.findIndex((s) => s.id === site.id);
      if (index > -1)
        sites.value[index] = site;
    } else {
      sites.value.push(site);
    }

    closeSiteModal();
  }

  function confirmDelete(site: Site) {
    siteToDelete.value = site;
    showDeleteModal.value = true;
  }

  function cancelDelete() {
    showDeleteModal.value = false;
    siteToDelete.value = null;
  }

  async function handleDelete() {
    if (!siteToDelete.value)
      return;

    isDeleting.value = true;
    const url = ROUTES.sites_destroy.path.replace(':id', String(siteToDelete.value.id));
    const { success } = await execute(
      () => axios.delete(url),
      {
        showSuccessToast: true,
        successMessage: 'Site deleted successfully',
        showErrorToast: true,
        errorTitle: 'Delete Error'
      }
    );

    if (success) {
      if (sites.value) {
        const index = sites.value.findIndex((s) => s.id === siteToDelete.value!.id);
        if (index > -1)
          sites.value.splice(index, 1);
      }

      if (site.value && site.value.id === siteToDelete.value.id)
        window.location.reload();
    }

    isDeleting.value = false;
    showDeleteModal.value = false;
  }

  function formatLocation(site: Site): string {
    const parts = [];
    if (site.city)
      parts.push(site.city);
    if (site.country)
      parts.push(site.country);
    return parts.length > 0 ? parts.join(', ') : 'Location not specified';
  }

  function formatCoordinates(site: Site): string {
    if (!site.latitude || !site.longitude)
      return '';
    const lat = Number(site.latitude).toFixed(4);
    const lng = Number(site.longitude).toFixed(4);
    return `${lat}°, ${lng}°`;
  }

  function getSegmentCount(siteId: Site['id']) {
    return pageProps.value.segments.filter((segment: Segment) =>
      segment.site_id === siteId
    ).length;
  }

  function getSegmentsName(siteId: Site['id']) {
    const segments = pageProps.value.segments.filter((segment: Segment) =>
      segment.site_id === siteId
    );
    if (segments.length === 0)
      return 'No segments assigned';
    return segments.map((segment: Segment) => segment.name).join(', ');
  }

  function getUserCount(siteId: Site['id']) {
    return pageProps.value.siteUsers.filter((siteUser: SiteUser) =>
      siteUser.site_id === siteId
    ).length;
  }

  function getUsersName(siteId: Site['id']) {
    const users = pageProps.value.siteUsers.filter((siteUser: SiteUser) =>
      siteUser.site_id === siteId
    );
    if (users.length === 0)
      return 'No users assigned';
    return users.map((siteUser: SiteUser) => siteUser.user_name).join(', ');
  }
</script>

<style scoped>
</style>
