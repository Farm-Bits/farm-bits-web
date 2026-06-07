<template>
  <div class="px-4">
    <ErrorMessages class="mb-2" />

    <div class="row align-items-center py-3 border-bottom">
      <div class="col-md-3">
        <label class="form-label mb-0 fw-medium">Password</label>
      </div>
      <div class="col-md-6">
        <div v-if="!editing" class="d-flex align-items-center">
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
      <div v-if="permissions?.my_account.update" class="col-md-3 text-end">
        <div v-if="!editing">
          <CButton @click="startEditing()">
            <CIcon name="cilPencil" class="me-1" />
            Change Password
          </CButton>
        </div>
        <div v-else class="d-flex gap-2 justify-content-end">
          <CButton
            :disabled="!hasPasswordChanges() || hasPasswordErrors()"
            @click="savePassword()">
            <CIcon name="cilCheck" class="me-1" />
            Update Password
          </CButton>
          <CButton color="secondary" @click="cancelEditing()">
            <CIcon name="cilX" class="me-1" />
            Cancel
          </CButton>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import { useForm } from '@inertiajs/vue3';
  import { useVuelidate } from '@vuelidate/core';
  import { minLength, required, sameAs } from '@vuelidate/validators';
  import useAuth from '@/composables/useAuth';
  import usePermissions from '@/composables/usePermissions';

  const { paths } = useAuth();
  const { permissions } = usePermissions();

  const editing = ref(false);

  const formData = useForm({
    user: {
      current_password: '',
      password: '',
      password_confirmation: ''
    }
  });

  function rules() {
    return {
      user: {
        current_password: editing.value ? { required } : {},
        password: editing.value ? {
          required,
          minLength: minLength(8)
        } : {},
        password_confirmation: editing.value ? {
          required,
          sameAs: sameAs(formData.user.password)
        } : {}
      }
    };
  }

  const v$ = useVuelidate(rules, formData);

  function startEditing() {
    editing.value = true;
    resetForm();
  }

  function cancelEditing() {
    editing.value = false;
    resetForm();
    v$.value.user.current_password.$reset();
    v$.value.user.password.$reset();
    v$.value.user.password_confirmation.$reset();
  }

  function resetForm() {
    formData.user.current_password = '';
    formData.user.password = '';
    formData.user.password_confirmation = '';
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

  async function savePassword() {
    await v$.value.user.current_password.$validate();
    await v$.value.user.password.$validate();
    await v$.value.user.password_confirmation.$validate();

    const isValid = !v$.value.user.current_password.$error &&
      !v$.value.user.password.$error &&
      !v$.value.user.password_confirmation.$error;
    if (!isValid)
      return;

    formData.put(paths.value.pages.myAccount, {
      onSuccess: () => {
        editing.value = false;
        resetForm();
        v$.value.user.current_password.$reset();
        v$.value.user.password.$reset();
        v$.value.user.password_confirmation.$reset();
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
