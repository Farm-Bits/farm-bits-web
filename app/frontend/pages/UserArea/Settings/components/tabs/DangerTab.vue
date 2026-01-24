<template>
  <div class="p-4">
    <CAlert color="danger" class="d-flex align-items-start">
      <CIcon name="cilWarning" class="me-2 mt-1" />
      <p class="mb-0">Actions in this section are irreversible and will permanently delete data.</p>
    </CAlert>

    <CCard class="border-danger">
      <CCardBody>
        <div class="row align-items-center">
          <div class="col-md-8">
            <h6 class="text-danger mb-2">Delete Company</h6>
            <p class="text-muted mb-0">
              Permanently delete this company and all associated data. This action cannot be undone.
            </p>
            <ul class="text-muted small mt-2 mb-0">
              <li>All company data and settings</li>
              <li>All associated sites and measurements</li>
              <li>All user access to this company</li>
            </ul>
          </div>
          <div class="col-md-4 text-end">
            <CButton color="danger" @click="showDeleteModal = true">
              <CIcon name="cilTrash" class="me-2" />
              Delete Company
            </CButton>
          </div>
        </div>
      </CCardBody>
    </CCard>

    <CModal
      :visible="showDeleteModal"
      @close="closeDeleteModal"
      backdrop="static">
      <CModalHeader>
        <CModalTitle class="text-danger">Delete Company</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <CAlert color="danger">
          <CIcon name="cilWarning" class="me-2" />
          This action cannot be undone!
        </CAlert>
        <p class="mb-3">
          You are about to permanently delete <strong>{{ currentCompany?.name }}</strong> and all associated data.
        </p>
        <div class="mb-3">
          <CFormLabel for="confirmDelete">
            Type <strong>{{ currentCompany?.name }}</strong> to confirm:
          </CFormLabel>
          <CFormInput
            id="confirmDelete"
            v-model="deleteConfirmation"
            :placeholder="currentCompany?.name"
            :invalid="deleteConfirmationError" />
          <CFormFeedback :invalid="true" v-if="deleteConfirmationError">
            Company name does not match
          </CFormFeedback>
        </div>
      </CModalBody>
      <CModalFooter>
        <CButton
          color="secondary"
          @click="closeDeleteModal">
          Cancel
        </CButton>
        <form
          ref="deleteForm"
          @submit.prevent="deleteCompany"
          :action="paths.actions.companySetup"
          method="post">
          <input type="hidden" name="_method" value="delete">
          <CButton
            color="danger"
            type="submit"
            :disabled="deleteConfirmation !== currentCompany?.name">
            <CIcon name="cilTrash" class="me-2" />
            Delete Company
          </CButton>
        </form>
      </CModalFooter>
    </CModal>
  </div>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import useAuth from '@/composables/useAuth';

  const { paths, currentCompany } = useAuth();

  const showDeleteModal = ref(false);
  const deleteConfirmation = ref('');
  const deleteConfirmationError = ref(false);
  const deleteForm = ref<HTMLFormElement>();

  function closeDeleteModal() {
    showDeleteModal.value = false;
    deleteConfirmation.value = '';
    deleteConfirmationError.value = false;
  }

  function deleteCompany() {
    // if (!features.value.canManageCompanySettings)
    //   return;

    if (deleteConfirmation.value !== currentCompany.value?.name) {
      deleteConfirmationError.value = true;
      return;
    }

    if (confirm('Are you absolutely sure? This action cannot be undone.'))
      deleteForm.value?.submit();
  }
</script>

<style scoped>
</style>
