<template>
  <div class="p-4">
    <div class="mb-4">
      <h5 class="mb-3">Profile Information</h5>
      <ErrorMessages class="mb-4" />
    </div>

    <!-- Name Field -->
    <div class="row align-items-center py-3 border-bottom">
      <div class="col-md-3">
        <label class="form-label mb-0 fw-medium">Full Name</label>
      </div>
      <div class="col-md-6">
        <div v-if="!editingFields.user.name" class="d-flex align-items-center">
          <span class="text-body">{{ formData.user.name }}</span>
        </div>
        <div v-else>
          <CFormInput
            placeholder="Enter your full name"
            class="mb-2"
            v-model="formData.user.name"
            :invalid="v$.user.name.$error"
            @blur="v$.user.name.$touch()" />
          <div class="form-error" v-if="v$.user.name.$error">
            {{ v$.user.name.$errors[0].$message }}
          </div>
        </div>
      </div>
      <div class="col-md-3 text-end">
        <div v-if="!editingFields.user.name">
          <CButton @click="startEditing('name')">
            <CIcon name="cilPencil" class="me-1" />
            Edit
          </CButton>
        </div>
        <div v-else class="d-flex gap-2 justify-content-end">
          <CButton
            :disabled="!hasChanges('name') || v$.user.name.$error"
            @click="saveField('name')">
            <CIcon name="cilCheck" class="me-1" />
            Update
          </CButton>
          <CButton color="secondary" @click="cancelEditing('name')">
            <CIcon name="cilX" class="me-1" />
            Cancel
          </CButton>
        </div>
      </div>
    </div>

    <!-- Email Field -->
    <div class="row align-items-center py-3 border-bottom">
      <div class="col-md-3">
        <label class="form-label mb-0 fw-medium">Email Address</label>
      </div>
      <div class="col-md-6">
        <div v-if="!editingFields.user.email" class="d-flex align-items-center">
          <span class="text-body">{{ formData.user.email }}</span>
        </div>
        <div v-else>
          <CFormInput
            type="email"
            placeholder="Enter your email address"
            class="mb-2"
            v-model="formData.user.email"
            :invalid="v$.user.email.$error"
            @blur="v$.user.email.$touch()" />
          <div class="form-error" v-if="v$.user.email.$error">
            {{ v$.user.email.$errors[0].$message }}
          </div>
        </div>
      </div>
      <div class="col-md-3 text-end">
        <div v-if="!editingFields.user.email">
          <CButton @click="startEditing('email')">
            <CIcon name="cilPencil" class="me-1" />
            Edit
          </CButton>
        </div>
        <div v-else class="d-flex gap-2 justify-content-end">
          <CButton
            :disabled="!hasChanges('email') || v$.user.email.$error"
            @click="saveField('email')">
            <CIcon name="cilCheck" class="me-1" />
            Update
          </CButton>
          <CButton color="secondary" @click="cancelEditing('email')">
            <CIcon name="cilX" class="me-1" />
            Cancel
          </CButton>
        </div>
      </div>
    </div>

    <!-- Password Field -->
    <div class="row align-items-center py-3 border-bottom">
      <div class="col-md-3">
        <label class="form-label mb-0 fw-medium">Password</label>
      </div>
      <div class="col-md-6">
        <div v-if="!editingFields.user.password" class="d-flex align-items-center">
          <span class="text-body text-muted">••••••••</span>
        </div>
        <div v-else>
          <CFormInput
            type="password"
            placeholder="Enter current password"
            class="mb-2"
            v-model="formData.user.current_password"
            :invalid="v$.user.current_password.$error"
            @blur="v$.user.current_password.$touch()" />
          <div class="form-error" v-if="v$.user.current_password.$error">
            {{ v$.user.current_password.$errors[0].$message }}
          </div>

          <CFormInput
            type="password"
            placeholder="Enter new password"
            class="mb-2"
            v-model="formData.user.password"
            :invalid="v$.user.password.$error"
            @blur="v$.user.password.$touch()" />
          <div class="form-error" v-if="v$.user.password.$error">
            {{ v$.user.password.$errors[0].$message }}
          </div>

          <CFormInput
            type="password"
            placeholder="Confirm new password"
            class="mb-2"
            v-model="formData.user.password_confirmation"
            :invalid="v$.user.password_confirmation.$error"
            @blur="v$.user.password_confirmation.$touch()" />
          <div class="form-error" v-if="v$.user.password_confirmation.$error">
            {{ v$.user.password_confirmation.$errors[0].$message }}
          </div>
        </div>
      </div>
      <div class="col-md-3 text-end">
        <div v-if="!editingFields.user.password">
          <CButton @click="startEditing('password')">
            <CIcon name="cilPencil" class="me-1" />
            Change Password
          </CButton>
        </div>
        <div v-else class="d-flex gap-2 justify-content-end">
          <CButton
            :disabled="!hasPasswordChanges() || hasPasswordErrors()"
            @click="saveField('password')">
            <CIcon name="cilCheck" class="me-1" />
            Update Password
          </CButton>
          <CButton color="secondary" @click="cancelEditing('password')">
            <CIcon name="cilX" class="me-1" />
            Cancel
          </CButton>
        </div>
      </div>
    </div>

    <!-- Account Deactivation -->
    <div class="row align-items-center py-3">
      <div class="col-md-3">
        <label class="form-label mb-0 fw-medium text-danger">Danger Zone</label>
      </div>
      <div class="col-md-6">
        <div class="text-body">
          <p class="mb-2">Deactivate your account</p>
          <small class="text-muted">
            This will deactivate your account and you will no longer be able to log in.
            This action can be reversed by contacting support.
          </small>
        </div>
      </div>
      <div class="col-md-3 text-end">
        <CButton
          color="danger"
          variant="outline"
          @click="showDeactivateModal = true">
          <CIcon name="cilWarning" class="me-1" />
          Deactivate Account
        </CButton>
      </div>
    </div>

    <!-- Deactivation Confirmation Modal -->
    <CModal
      :visible="showDeactivateModal"
      @close="showDeactivateModal = false"
      backdrop="static">
      <CModalHeader>
        <CModalTitle>Confirm Account Deactivation</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <div class="mb-3">
          <p class="text-danger fw-medium mb-2">
            <CIcon name="cilWarning" class="me-1" />
            Are you sure you want to deactivate your account?
          </p>
          <p class="mb-3">This action will:</p>
          <ul class="mb-3">
            <li>Prevent you from logging in</li>
            <li>Hide your profile from other users</li>
            <li>Suspend access to all your data</li>
          </ul>
          <p class="mb-3">
            <strong>Note:</strong> You can contact support to reactivate your account later.
          </p>
        </div>

        <div class="mb-3">
          <label class="form-label fw-medium">
            Enter your current password to confirm:
          </label>
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
        <CButton
          color="secondary"
          @click="cancelDeactivation()">
          Cancel
        </CButton>
        <CButton
          color="danger"
          :disabled="!deactivatePassword"
          @click="deactivateAccount()">
          <CIcon name="cilWarning" class="me-1" />
          Deactivate Account
        </CButton>
      </CModalFooter>
    </CModal>
  </div>
</template>

<script lang="ts" setup>
  import { reactive, ref } from 'vue';
  import { useForm } from '@inertiajs/vue3';
  import { useVuelidate } from '@vuelidate/core';
  import { email, minLength, required, sameAs } from '@vuelidate/validators';
  import useAuth from '@/composables/useAuth';

  const { paths, currentUser } = useAuth();

  type UserField = 'name' | 'email' | 'password';

  const formData = useForm({
    user: {
      name: currentUser.value?.name,
      email: currentUser.value?.email,
      current_password: '',
      password: '',
      password_confirmation: ''
    }
  });
  const originalData = reactive({
    user: {
      name: currentUser.value?.name,
      email: currentUser.value?.email
    }
  });
  const editingFields = reactive({
    user: {
      name: false,
      email: false,
      password: false
    }
  });

  const showDeactivateModal = ref(false);
  const deactivatePassword = ref('');
  const deactivatePasswordError = ref('');

  function rules() {
    return {
      user: {
        name: { required },
        email: { required, email },
        current_password: editingFields.user.password ? { required } : {},
        password: editingFields.user.password ? {
          required,
          minLength: minLength(8)
        } : {},
        password_confirmation: editingFields.user.password ? {
          required,
          sameAs: sameAs(formData.user.password)
        } : {}
      }
    };
  }

  const v$ = useVuelidate(rules, formData);

  function startEditing(field: UserField) {
    editingFields.user[field] = true;

    if (field === 'password') {
      formData.user.current_password = '';
      formData.user.password = '';
      formData.user.password_confirmation = '';
    }
  }

  function cancelEditing(field: UserField) {
    if (field === 'password') {
      formData.user.current_password = '';
      formData.user.password = '';
      formData.user.password_confirmation = '';
    } else
      formData.user[field] = originalData.user[field];

    editingFields.user[field] = false;
    v$.value.user[field].$reset();

    if (field === 'password') {
      v$.value.user.current_password.$reset();
      v$.value.user.password.$reset();
      v$.value.user.password_confirmation.$reset();
    }
  }

  function hasChanges(field: UserField) {
    if (field === 'password') {
      return formData.user.current_password !== '' ||
             formData.user.password !== '' ||
             formData.user.password_confirmation !== '';
    }
    return formData.user[field] !== originalData.user[field];
  }

  function hasPasswordChanges() {
    return formData.user.current_password !== '' &&
           formData.user.password !== '' &&
           formData.user.password_confirmation !== '';
  }

  function hasPasswordErrors() {
    return v$.value.user.current_password.$error ||
           v$.value.user.password.$error ||
           v$.value.user.password_confirmation.$error;
  }

  async function saveField(field: UserField) {
    let isValid = false;

    if (field === 'password') {
      await v$.value.user.current_password.$validate();
      await v$.value.user.password.$validate();
      await v$.value.user.password_confirmation.$validate();

      isValid = !v$.value.user.current_password.$error &&
                !v$.value.user.password.$error &&
                !v$.value.user.password_confirmation.$error;
    } else
      isValid = await v$.value.user[field].$validate();

    if (!isValid)
      return;

    let transformData;
    if (field === 'password') {
      transformData = {
        user: {
          current_password: formData.user.current_password,
          password: formData.user.password,
          password_confirmation: formData.user.password_confirmation
        }
      };
    } else
      transformData = { user: { [field]: formData.user[field] } };

    formData.transform(() => transformData)
      .put(paths.value.pages.myAccount, {
        onSuccess: () => {
          if (field !== 'password')
            originalData.user[field] = formData.user[field];
          else {
            formData.user.current_password = '';
            formData.user.password = '';
            formData.user.password_confirmation = '';

            v$.value.user.current_password.$reset();
            v$.value.user.password.$reset();
            v$.value.user.password_confirmation.$reset();
          }
          editingFields.user[field] = false;
          v$.value.user[field].$reset();
        }
      });
  }

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
      onError: () => {
        cancelDeactivation();
      }
    });
  }
</script>

<style scoped>
  .form-error {
    color: #dc3545;
    font-size: 0.875rem;
    margin-top: 0.25rem;
  }

  @media (max-width: 768px) {
    .row.align-items-center .col-md-3,
    .row.align-items-center .col-md-6,
    .row.align-items-center .col-md-3 {
      margin-bottom: 0.5rem;
    }

    .text-end {
      text-align: left !important;
    }
  }
</style>
