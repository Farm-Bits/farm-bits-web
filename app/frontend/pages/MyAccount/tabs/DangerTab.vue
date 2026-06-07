<template>
  <div class="px-4">
    <ErrorMessages class="mb-2" />

    <CAlert color="danger" class="d-flex align-items-start">
      <CIcon name="cilWarning" class="me-2 mt-1" />
      <p class="mb-0">Actions in this section will deactivate your account.</p>
    </CAlert>

    <CCard class="border-danger">
      <CCardBody>
        <div class="row align-items-center">
          <div class="col-md-8">
            <h6 class="text-danger mb-2">Deactivate Account</h6>
            <p class="text-muted mb-2">
              Deactivate your account and end all access to {{ currentCompany?.name }}.
            </p>
            <ul class="text-muted small mt-2 mb-0">
              <li>You will no longer be able to log in</li>
              <li>Your profile will be hidden from other users</li>
              <li>This action can be reversed by contacting support</li>
            </ul>
          </div>
          <div class="col-md-4 text-end">
            <CButton color="danger" @click="showDeactivateModal = true">
              <CIcon name="cilWarning" class="me-2" />
              Deactivate Account
            </CButton>
          </div>
        </div>
      </CCardBody>
    </CCard>

    <CModal
      :visible="showDeactivateModal"
      @close="cancelDeactivation"
      backdrop="static">
      <CModalHeader>
        <CModalTitle class="text-danger">Confirm Account Deactivation</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <CAlert color="danger">
          <CIcon name="cilWarning" class="me-2" />
          Are you sure you want to deactivate your account?
        </CAlert>

        <p class="mb-2">This action will:</p>
        <ul class="mb-3">
          <li>Prevent you from logging in</li>
          <li>Hide your profile from other users</li>
          <li>Suspend access to all your data</li>
        </ul>
        <p class="mb-3">
          <strong>Note:</strong> You can contact support to reactivate your account later.
        </p>

        <div class="mb-3">
          <CFormLabel>Enter your current password to confirm:</CFormLabel>
          <CFormInput
            v-model="deactivatePassword"
            type="password"
            placeholder="Enter your password"
            :invalid="deactivatePasswordError !== ''"
            class="mb-2" />
          <div class="form-error" v-if="deactivatePasswordError">
            {{ deactivatePasswordError }}
          </div>
        </div>
      </CModalBody>
      <CModalFooter>
        <CButton color="secondary" @click="cancelDeactivation">
          Cancel
        </CButton>
        <CButton
          color="danger"
          :disabled="!deactivatePassword"
          @click="deactivateAccount">
          <CIcon name="cilWarning" class="me-1" />
          Deactivate Account
        </CButton>
      </CModalFooter>
    </CModal>
  </div>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import { useForm } from '@inertiajs/vue3';
  import useAuth from '@/composables/useAuth';

  const { paths, currentCompany } = useAuth();

  const showDeactivateModal = ref(false);
  const deactivatePassword = ref('');
  const deactivatePasswordError = ref('');

  function cancelDeactivation() {
    showDeactivateModal.value = false;
    deactivatePassword.value = '';
    deactivatePasswordError.value = '';
  }

  function deactivateAccount() {
    if (!deactivatePassword.value) {
      deactivatePasswordError.value = 'Password is required';
      return;
    }

    const deactivateForm = useForm({
      user: { password: deactivatePassword.value }
    });

    deactivateForm.delete(paths.value.pages.myAccount, {
      onError: () => cancelDeactivation()
    });
  }
</script>

<style scoped>
  .form-error {
    color: #dc3545;
    font-size: 0.875rem;
    margin-top: 0.25rem;
  }
</style>
