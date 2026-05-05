<template>
  <div class="p-4">
    <ErrorMessages class="mb-4" />

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
      <div v-if="permissions?.my_account.update" class="col-md-3 text-end">
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
      <div v-if="permissions?.my_account.update" class="col-md-3 text-end">
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
  </div>
</template>

<script lang="ts" setup>
  import { reactive } from 'vue';
  import { useForm } from '@inertiajs/vue3';
  import { useVuelidate } from '@vuelidate/core';
  import { email, required } from '@vuelidate/validators';
  import useAuth from '@/composables/useAuth';
  import usePermissions from '@/composables/usePermissions';
  import { type User } from '@/types/inertia';

  const { paths, currentUser } = useAuth();
  const { permissions } = usePermissions();

  type ProfileField = Extract<keyof User, 'name' | 'email'>;

  const formData = useForm({
    user: {
      name: currentUser.value?.name ?? '',
      email: currentUser.value?.email ?? ''
    }
  });
  const originalData = reactive({
    user: {
      name: currentUser.value?.name ?? '',
      email: currentUser.value?.email ?? ''
    }
  });
  const editingFields = reactive({
    user: {
      name: false,
      email: false
    }
  });

  function rules() {
    return {
      user: {
        name: { required },
        email: { required, email }
      }
    };
  }

  const v$ = useVuelidate(rules, formData);

  function startEditing(field: ProfileField) {
    editingFields.user[field] = true;
  }

  function cancelEditing(field: ProfileField) {
    formData.user[field] = originalData.user[field];
    editingFields.user[field] = false;
    v$.value.user[field].$reset();
  }

  function hasChanges(field: ProfileField) {
    return formData.user[field] !== originalData.user[field];
  }

  async function saveField(field: ProfileField) {
    const isValid = await v$.value.user[field].$validate();
    if (!isValid)
      return;

    formData.transform(() => ({ user: { [field]: formData.user[field] } }))
      .put(paths.value.pages.myAccount, {
        onSuccess: () => {
          originalData.user[field] = formData.user[field];
          editingFields.user[field] = false;
          v$.value.user[field].$reset();
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
