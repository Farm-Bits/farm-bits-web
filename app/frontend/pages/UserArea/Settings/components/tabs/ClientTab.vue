<template>
  <div class="p-4">
    <div class="mb-4">
      <h5 class="mb-3">Company Information</h5>
      <ErrorMessages class="mb-4" />
    </div>

    <div class="row align-items-center py-3 border-bottom">
      <div class="col-md-3">
        <label class="form-label mb-0 fw-medium">Company Name</label>
      </div>
      <div class="col-md-6">
        <div v-if="!editingFields.client.name" class="d-flex align-items-center">
          <span class="text-body">{{ formData.client.name }}</span>
        </div>
        <div v-else>
          <CFormInput
            v-model="formData.client.name"
            placeholder="Enter company name"
            :invalid="v$.client.name.$error"
            @blur="v$.client.name.$touch()"
            class="mb-2" />
          <div class="form-error" v-if="v$.client.name.$error">
            {{ v$.client.name.$errors[0].$message }}
          </div>
        </div>
      </div>
      <div class="col-md-3 text-end">
        <div v-if="!editingFields.client.name">
          <CButton @click="startEditing('name')">
            <CIcon name="cilPencil" class="me-1" />
            Edit
          </CButton>
        </div>
        <div v-else class="d-flex gap-2 justify-content-end">
          <CButton
            :disabled="!hasChanges('name') || v$.client.name.$error"
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
        <div v-if="!editingFields.client.color" class="d-flex align-items-center">
          <div
            class="color-preview me-2"
            :style="{ backgroundColor: formData.client.color }"></div>
          <span class="text-body">{{ formData.client.color }}</span>
        </div>
        <div v-else>
          <div class="d-flex align-items-center gap-2 mb-2">
            <ColorPicker
              v-model="formData.client.color"
              :invalid="v$.client.color.$error"
              @blur="v$.client.color.$touch()" />
          </div>
          <div class="form-error" v-if="v$.client.color.$error">
            {{ v$.client.color.$errors[0].$message }}
          </div>
        </div>
      </div>
      <div class="col-md-3 text-end">
        <div v-if="!editingFields.client.color">
          <CButton @click="startEditing('color')">
            <CIcon name="cilPencil" class="me-1" />
            Edit
          </CButton>
        </div>
        <div v-else class="d-flex gap-2 justify-content-end">
          <CButton
            :disabled="!hasChanges('color') || v$.client.color.$error"
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
  </div>
</template>

<script lang="ts" setup>
  import { reactive } from 'vue';
  import { useForm } from '@inertiajs/vue3';
  import { useVuelidate } from '@vuelidate/core';
  import { required } from '@vuelidate/validators';
  import ColorPicker from '@/components/ColorPicker.vue';
  import useAuth from '@/composables/useAuth';
  import { type Client } from '@/types/inertia';

  const { pageProps, paths } = useAuth<{
    client: Client
  }>();

  type ClientField = Exclude<keyof Client, 'id'>;

  const formData = useForm({
    client: {
      ...pageProps.value.client
    }
  });
  const originalData = reactive({
    client: {
      ...pageProps.value.client
    }
  });
  const editingFields = reactive({
    client: {
      name: false,
      color: false
    }
  });

  function isValidHexColor(value: string | null) {
    if (!value)
      return true;
    return /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(value);
  }

  function rules() {
    return {
      client: {
        name: { required },
        color: {
          required,
          isValidHexColor: {
            $validator: isValidHexColor,
            $message: 'Please enter a valid hex color (e.g., #FF0000)'
          }
        }
      }
    };
  }

  const v$ = useVuelidate(rules, formData);

  function startEditing(field: ClientField) {
    editingFields.client[field] = true;
  }

  function cancelEditing(field: ClientField) {
    formData.client[field] = originalData.client[field];
    editingFields.client[field] = false;
    v$.value.client[field].$reset();
  }

  function hasChanges(field: ClientField) {
    return formData.client[field] !== originalData.client[field];
  }

  async function saveField(field: ClientField) {
    // if (!features.value.canManageClientSettings)
    //   return;

    const fieldValidation = v$.value.client[field];
    await fieldValidation.$validate();

    const isValid = await v$.value.client[field].$validate();
    if (!isValid)
      return;

    formData.transform((data) => {
      return { client: { [field]: data.client[field] } };
    }).put(paths.value.actions.clientSetup, {
      onSuccess: () => {
        originalData.client[field] = formData.client[field];
        editingFields.client  [field] = false;
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
