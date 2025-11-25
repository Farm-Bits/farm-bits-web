<template>
  <div class="container-fluid py-4">
    <CRow class="mb-4">
      <CCol>
        <div class="d-flex justify-content-between align-items-center">
          <h2>Site Management</h2>
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

    <!-- Sites List -->
    <CRow v-if="sites && sites.length > 0">
      <CCol
        v-for="site in sites"
        :key="site.id"
        xs="12"
        md="6"
        lg="4"
        class="mb-4">
        <CCard>
          <CCardBody>
            <div class="d-flex justify-content-between align-items-start mb-3">
              <CCardTitle>{{ site.name }}</CCardTitle>
              <div class="d-flex gap-2">
                <CButton
                  v-if="permissions.sites.update"
                  color="light"
                  size="sm"
                  @click="openEditModal(site)">
                  <CIcon name="cilPencil" />
                </CButton>
                <CButton
                  v-if="permissions.sites.destroy"
                  color="light"
                  size="sm"
                  @click="confirmDelete(site)">
                  <CIcon name="cilTrash" />
                </CButton>
              </div>
            </div>

            <CCardText>
              <div class="mb-2">
                <strong>Location:</strong>
                <div class="text-muted">
                  {{ formatLocation(site) }}
                </div>
              </div>

              <div v-if="site.latitude && site.longitude" class="mb-2">
                <strong>Coordinates:</strong>
                <div class="text-muted">
                  {{ formatCoordinates(site) }}
                </div>
              </div>

              <div v-if="site.altitude" class="mb-2">
                <strong>Altitude:</strong>
                <div class="text-muted">
                  {{ site.altitude }}m
                </div>
              </div>
            </CCardText>
          </CCardBody>
        </CCard>
      </CCol>
    </CRow>

    <!-- Empty State -->
    <CRow v-else>
      <CCol>
        <CCard class="text-center py-5">
          <CCardBody>
            <CIcon name="cilLocationPin" size="3xl" class="text-muted mb-3" />
            <h4 class="text-muted mb-3">No Sites Yet</h4>
            <p class="text-muted mb-4">
              Get started by creating your first site to track farm locations.
            </p>
            <CButton
              v-if="permissions.sites.create"
              color="primary"
              @click="openCreateModal">
              <CIcon name="cilPlus" class="me-2" />
              Create Your First Site
            </CButton>
          </CCardBody>
        </CCard>
      </CCol>
    </CRow>

    <!-- Site Modal -->
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
        <p class="text-danger mb-0">This action cannot be undone.</p>
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
  import type { Site } from '@/types/inertia';
  import { ROUTES } from '@/types/permissions';

  const { sites } = useAuth();
  const { permissions } = usePermissions();
  const { execute } = useApiCall();

  // Site Modal State
  const showSiteModal = ref(false);
  const selectedSite = ref<Site | null>(null);

  // Delete Modal State
  const showDeleteModal = ref(false);
  const siteToDelete = ref<Site | null>(null);
  const isDeleting = ref(false);

  function openCreateModal() {
    selectedSite.value = null;
    showSiteModal.value = true;
  }

  function openEditModal(site: Site) {
    selectedSite.value = site;
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
    } else
      sites.value?.push(site);

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
        successMessage: 'Site removed successfully',
        showErrorToast: true,
        errorTitle: 'Remove Site Error'
      }
    );

    if (success && sites.value) {
      const index = sites.value.findIndex((s) => s.id === siteToDelete.value!.id);
      if (index > -1)
        sites.value.splice(index, 1);
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
    const latDir = Number(site.latitude) >= 0 ? 'N' : 'S';
    const lngDir = Number(site.longitude) >= 0 ? 'E' : 'W';

    return `${Math.abs(Number(lat))}° ${latDir}, ${Math.abs(Number(lng))}° ${lngDir}`;
  }
</script>

<style scoped>
  .gap-2 {
    gap: 0.5rem;
  }
</style>
