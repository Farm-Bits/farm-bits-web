<template>
  <CCard>
    <CCardHeader>
      <div class="d-flex justify-content-between align-items-center">
        <div>
          <h5 class="mb-1">Sites Management</h5>
          <p class="text-medium-emphasis small mb-0">
            Manage your farm sites and their configurations
          </p>
        </div>
        <CButton
          v-if="permissions?.sites.create"
          color="primary"
          size="sm"
          @click="openSiteModal">
          <CIcon name="cilPlus" class="me-2" />
          Add Site
        </CButton>
      </div>
    </CCardHeader>

    <CCardBody>
      <CTable hover responsive>
        <CTableHead>
          <CTableRow>
            <CTableHeaderCell>Site</CTableHeaderCell>
            <CTableHeaderCell>Location</CTableHeaderCell>
            <CTableHeaderCell>Time Zone</CTableHeaderCell>
            <CTableHeaderCell>Segments</CTableHeaderCell>
            <CTableHeaderCell style="width: 100px">Actions</CTableHeaderCell>
          </CTableRow>
        </CTableHead>
        <CTableBody>
          <CTableRow v-for="siteAvailable in sitesAvailable" :key="siteAvailable.id">
            <CTableDataCell>
              <div class="fw-semibold">{{ siteAvailable.name }}</div>
            </CTableDataCell>
            <CTableDataCell>
              <p class="mb-1 text-muted small">
                <CIcon name="cilLocationPin" size="sm" class="me-1" />
                {{ formatLocation(siteAvailable) }}
              </p>
              <div v-if="siteAvailable.latitude && siteAvailable.longitude" class="d-flex gap-3 small text-muted">
                <span>{{ formatCoordinates(siteAvailable) }}</span>
              </div>
            </CTableDataCell>
            <CTableDataCell>
              <p class="mb-1 text-muted small">
                {{ formatTimeZone(siteAvailable.time_zone) }}
              </p>
            </CTableDataCell>
            <CTableDataCell>
              <div v-if="siteAvailable.segments.length > 0" class="d-flex flex-wrap gap-1">
                <CBadge
                  v-for="segment in siteAvailable.segments"
                  :key="segment.id"
                  color="secondary">
                  {{ segment.name }}
                </CBadge>
              </div>
              <div v-else class="small text-medium-emphasis">
                No segments
              </div>
            </CTableDataCell>
            <CTableDataCell>
              <CButtonGroup size="sm">
                <CTooltip
                  v-if="permissions?.sites.update"
                  content="Configure Site">
                  <template #toggler="{ id, on }">
                    <CButton
                      v-on="on"
                      color="light"
                      @click="openSiteModal(siteAvailable)">
                      <CIcon name="cilSettings" class="me-1" />
                    </CButton>
                  </template>
                </CTooltip>
                <CTooltip
                  v-if="permissions?.sites.destroy"
                  content="Delete Site">
                  <template #toggler="{ id, on }">
                    <CButton
                      v-on="on"
                      color="light"
                      @click="openDeleteSiteModal(siteAvailable)">
                      <CIcon name="cilTrash" class="me-1" />
                    </CButton>
                  </template>
                </CTooltip>
              </CButtonGroup>
            </CTableDataCell>
          </CTableRow>
        </CTableBody>
      </CTable>
    </CCardBody>

    <!-- Site Modal (Create/Edit) -->
    <SiteModal
      :visible="showSiteModal"
      :site="selectedSite"
      @close="closeSiteModal"
      @success="handleSiteUpdate" />

    <!-- Delete Confirmation Modal -->
    <CModal
      :visible="showDeleteModal"
      @close="closeDeleteSiteModal">
      <CModalHeader>
        <CModalTitle>Confirm Deletion</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <p>Are you sure you want to delete <strong>{{ siteToDelete?.name }}</strong>?</p>
        <p class="text-danger mb-0">
          <CIcon name="cilWarning" class="me-2" />
          This will also delete all segments, gateways, and data associated with this site.
        </p>
      </CModalBody>
      <CModalFooter>
        <CButton
          color="secondary"
          @click="closeDeleteSiteModal">
          Cancel
        </CButton>
        <CButton
          color="danger"
          :disabled="isDeleting"
          @click="handleDeleteSite">
          <CSpinner v-if="isDeleting" size="sm" class="me-2" />
          {{ isDeleting ? 'Deleting...' : 'Delete' }}
        </CButton>
      </CModalFooter>
    </CModal>
  </CCard>
</template>

<script lang="ts" setup>
  import { onMounted, ref } from 'vue';
  import axios from 'axios';
  import SiteModal from '@/components/SiteModal.vue';
  import useAuth from '@/composables/useAuth';
  import usePermissions from '@/composables/usePermissions';
  import { useApiCall } from '@/composables/useApi';
  import type { SiteWithSegments } from '@/types/inertia';
  import type { Site } from '@/types/location';
  import { ROUTES } from '@/types/permissions';

  const { currentSite, accessibleSites } = useAuth();
  const { permissions } = usePermissions();
  const { execute } = useApiCall();

  const sitesAvailable = ref<SiteWithSegments[]>([]);

  const showSiteModal = ref(false);
  const selectedSite = ref<SiteWithSegments | null>(null);

  const showDeleteModal = ref(false);
  const siteToDelete = ref<Site | null>(null);
  const isDeleting = ref(false);

  function formatLocation(siteItem: Site) {
    const parts = [];
    if (siteItem.city)
      parts.push(siteItem.city);
    if (siteItem.country)
      parts.push(siteItem.country);
    return parts.length > 0 ? parts.join(', ') : 'Location not specified';
  }

  function formatCoordinates(siteItem: Site) {
    if (!siteItem.latitude || !siteItem.longitude)
      return '';
    const lat = Number(siteItem.latitude).toFixed(4);
    const lng = Number(siteItem.longitude).toFixed(4);
    return `${lat}°, ${lng}°`;
  }

  function formatTimeZone(timeZone: string) {
    return timeZone.replace(/_/g, ' ');
  }

  function openSiteModal(site: SiteWithSegments | null = null) {
    selectedSite.value = site;
    showSiteModal.value = true;
  }

  function closeSiteModal() {
    showSiteModal.value = false;
    selectedSite.value = null;
  }

  function openDeleteSiteModal(siteItem: Site) {
    siteToDelete.value = siteItem;
    showDeleteModal.value = true;
  }

  function closeDeleteSiteModal() {
    showDeleteModal.value = false;
    siteToDelete.value = null;
  }

  function handleSiteUpdate(updatedSite: SiteWithSegments) {
    if (accessibleSites.value) {
      const index = accessibleSites.value.findIndex((s) => s.id === updatedSite.id);
      if (index > -1)
        accessibleSites.value[index] = updatedSite;
      else
        accessibleSites.value.push(updatedSite);
    }

    const availableIndex = sitesAvailable.value.findIndex((s) => s.id === updatedSite.id);
    if (availableIndex > -1)
      sitesAvailable.value[availableIndex] = updatedSite;
    else
      sitesAvailable.value.push(updatedSite);

    if (currentSite.value && currentSite.value.id === updatedSite.id)
      Object.assign(currentSite.value, updatedSite);

    closeSiteModal();
  }

  async function handleDeleteSite() {
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
      if (accessibleSites.value) {
        const index = accessibleSites.value.findIndex((s) => s.id === siteToDelete.value!.id);
        if (index > -1)
          accessibleSites.value.splice(index, 1);

        const availableIndex = sitesAvailable.value.findIndex((s) => s.id === siteToDelete.value!.id);
        if (availableIndex > -1)
          sitesAvailable.value.splice(availableIndex, 1);
      }

      if (currentSite.value && currentSite.value.id === siteToDelete.value.id)
        window.location.reload();

      closeDeleteSiteModal();
    }

    isDeleting.value = false;
  }

  async function loadSites() {
    if (!permissions.value?.sites.index)
      return;

    const { success, data } = await execute<SiteWithSegments[]>(
      () => axios.get(ROUTES.sites_index.path),
      { errorTitle: 'Load Sites Error', showErrorToast: true }
    );

    if (success)
      sitesAvailable.value = data;
  }

  onMounted(() => {
    loadSites();
  });
</script>

<style scoped>
  .list-group-item {
    border-left: 3px solid transparent;
    transition: all 0.2s ease;
  }

  .list-group-item:hover {
    border-left-color: var(--cui-primary);
    background-color: var(--cui-light);
  }
</style>
