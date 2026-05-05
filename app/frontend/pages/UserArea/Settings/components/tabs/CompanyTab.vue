<template>
  <div class="p-4">
    <div class="row align-items-center py-3 border-bottom">
      <div class="col-md-3">
        <label class="form-label mb-0 fw-medium">Company Name</label>
      </div>
      <div class="col-md-6">
        <div v-if="!editingFields.company.name" class="d-flex align-items-center">
          <span class="text-body">{{ formData.company.name }}</span>
        </div>
        <div v-else>
          <CFormInput
            v-model="formData.company.name"
            placeholder="Enter company name"
            :invalid="v$.company.name.$error"
            @blur="v$.company.name.$touch()"
            class="mb-2" />
          <div class="form-error" v-if="v$.company.name.$error">
            {{ v$.company.name.$errors[0].$message }}
          </div>
        </div>
      </div>
      <div v-if="permissions?.company_setup.update" class="col-md-3 text-end">
        <div v-if="!editingFields.company.name">
          <CButton @click="startEditing('name')">
            <CIcon name="cilPencil" class="me-1" />
            Edit
          </CButton>
        </div>
        <div v-else class="d-flex gap-2 justify-content-end">
          <CButton
            :disabled="!hasChanges('name') || v$.company.name.$error"
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

    <div class="row align-items-center py-3 border-bottom">
      <div class="col-md-3">
        <label class="form-label mb-0 fw-medium">Color</label>
      </div>
      <div class="col-md-6">
        <div v-if="!editingFields.company.color" class="d-flex align-items-center">
          <div
            class="color-preview me-2"
            :style="{ backgroundColor: formData.company.color }"></div>
          <span class="text-body">{{ formData.company.color }}</span>
        </div>
        <div v-else>
          <div class="d-flex align-items-center gap-2 mb-2">
            <ColorPicker
              v-model="formData.company.color"
              :invalid="v$.company.color.$error"
              @blur="v$.company.color.$touch()" />
          </div>
          <div class="form-error" v-if="v$.company.color.$error">
            {{ v$.company.color.$errors[0].$message }}
          </div>
        </div>
      </div>
      <div v-if="permissions?.company_setup.update" class="col-md-3 text-end">
        <div v-if="!editingFields.company.color">
          <CButton @click="startEditing('color')">
            <CIcon name="cilPencil" class="me-1" />
            Edit
          </CButton>
        </div>
        <div v-else class="d-flex gap-2 justify-content-end">
          <CButton
            :disabled="!hasChanges('color') || v$.company.color.$error"
            @click="saveField('color')">
            <CIcon name="cilCheck" class="me-1" />
            Update
          </CButton>
          <CButton color="secondary" @click="cancelEditing('color')">
            <CIcon name="cilX" class="me-1" />
            Cancel
          </CButton>
        </div>
      </div>
    </div>

    <!-- Require 2FA -->
    <div class="row align-items-center py-3 border-bottom">
      <div class="col-md-3">
        <label class="form-label mb-0 fw-medium">Require Two-Factor Authentication</label>
      </div>
      <div class="col-md-6">
        <div v-if="!editingFields.company.require_2fa" class="d-flex align-items-center">
          <CBadge :color="formData.company.require_2fa ? 'success' : 'secondary'">
            {{ formData.company.require_2fa ? 'Required' : 'Optional' }}
          </CBadge>
        </div>
        <div v-else>
          <CFormSwitch
            v-model="formData.company.require_2fa"
            :label="formData.company.require_2fa ? 'Required for all users' : 'Optional for users'" />
        </div>
        <small class="text-muted d-block mt-2">
          When required, every user in this company must have 2FA enabled.
          Users with 2FA off won't be able to disable it.
        </small>
      </div>
      <div v-if="permissions?.company_setup.update" class="col-md-3 text-end">
        <div v-if="!editingFields.company.require_2fa">
          <CButton @click="startEditing('require_2fa')">
            <CIcon name="cilPencil" class="me-1" />
            Edit
          </CButton>
        </div>
        <div v-else class="d-flex gap-2 justify-content-end">
          <CButton
            :disabled="!hasChanges('require_2fa')"
            @click="saveField('require_2fa')">
            <CIcon name="cilCheck" class="me-1" />
            Update
          </CButton>
          <CButton color="secondary" @click="cancelEditing('require_2fa')">
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
  import { required } from '@vuelidate/validators';
  import ColorPicker from '@/components/ColorPicker.vue';
  import useAuth from '@/composables/useAuth';
  import usePermissions from '@/composables/usePermissions';
  import { type Company } from '@/types/inertia';

  const { paths, currentCompany } = useAuth();
  const { permissions } = usePermissions();

  type CompanyField = Exclude<keyof Company, 'id'>;

  const formData = useForm({
    company: {
      name: '',
      color: '',
      require_2fa: false,
      ...currentCompany.value
    }
  });
  const originalData = reactive({
    company: {
      name: '',
      color: '',
      require_2fa: false,
      ...currentCompany.value
    }
  });
  const editingFields = reactive({
    company: {
      name: false,
      color: false,
      require_2fa: false
    }
  });

  function isValidHexColor(value: string | null) {
    if (!value)
      return true;
    return /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(value);
  }

  function rules() {
    return {
      company: {
        name: { required },
        color: {
          required,
          isValidHexColor: {
            $validator: isValidHexColor,
            $message: 'Please enter a valid hex color (e.g., #FF0000)'
          }
        },
        require_2fa: {}
      }
    };
  }

  const v$ = useVuelidate(rules, formData);

  function startEditing<K extends CompanyField>(field: K) {
    editingFields.company[field] = true;
  }

  function cancelEditing<K extends CompanyField>(field: K) {
    formData.company[field] = originalData.company[field];
    editingFields.company[field] = false;
    v$.value.company[field].$reset();
  }

  function hasChanges<K extends CompanyField>(field: K) {
    return formData.company[field] !== originalData.company[field];
  }

  async function saveField<K extends CompanyField>(field: K) {
    const isValid = await v$.value.company[field].$validate();
    if (!isValid)
      return;

    formData.transform((data) => {
      return { company: { [field]: data.company[field] } };
    }).put(paths.value.actions.companySetup, {
      onSuccess: () => {
        originalData.company[field] = formData.company[field];
        editingFields.company[field] = false;
      }
    });
  }
</script>

<style scoped>
  .color-preview {
    width: 24px;
    height: 24px;
    border-radius: 4px;
    border: 1px solid #dee2e6;
    display: inline-block;
  }

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
