<template>
  <div class="page-container py-12 px-4">
    <CContainer class="auth-card-wide mx-auto">
      <div class="auth-card overflow-hidden">
        <!-- Form -->
        <div class="p-8">
          <FlashMessages class="mb-6" />

          <CForm
            ref="form"
            @submit.prevent="handleSubmit"
            novalidate
            :action="paths.actions.clientSetup"
            method="post"
            class="form-section">
            <input type="hidden" name="_method" value="put">

            <!-- Company Information -->
            <div class="form-section">
              <h3 class="section-header-small">
                Company Information
              </h3>

              <div class="form-field">
                <label for="company" class="form-label">
                  Company Name *
                </label>
                <CFormInput
                  id="company"
                  placeholder="Enter your company name"
                  name="client[name]"
                  v-model="formData.name"
                  :invalid="v$.name.$error"
                  @blur="v$.name.$touch()"
                  class="form-input" />
                <div class="form-error" v-if="v$.name.$error">
                  {{ v$.name.$errors[0].$message }}
                </div>
              </div>

              <div class="form-field">
                <label class="form-label">
                  Company Color
                </label>
                <input name="client[color]" :value="formData.color" type="hidden" />
                <ColorPicker
                  v-model="formData.color"
                  :invalid="v$.color.$error"
                  @blur="v$.color.$touch()" />
                <div class="form-error" v-if="v$.color.$error">
                  {{ v$.color.$errors[0].$message }}
                </div>
              </div>
            </div>

            <!-- Submit Button -->
            <div class="form-submit-section">
              <CButton type="submit" class="btn-gradient-green btn-full-width text-lg">
                Update Company
              </CButton>
            </div>
          </CForm>
        </div>
      </div>

      <div class="danger-zone-card mt-6">
        <div class="danger-zone-header">
          <div class="d-flex align-items-center gap-2">
            <svg class="danger-icon" width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.19-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd" />
            </svg>
            <h3 class="danger-zone-title">Danger Zone</h3>
          </div>
        </div>

        <div class="danger-zone-content">
          <div class="danger-zone-info">
            <h4 class="danger-zone-action-title">Delete Company</h4>
            <div class="danger-zone-description">
              <p class="mb-2">
                <strong>This action cannot be undone.</strong> Deleting your company will permanently remove:
              </p>
              <ul class="danger-zone-list">
                <li>All company data and settings</li>
                <li>All associated sites and measurements</li>
                <li>All user access to this company</li>
              </ul>
              <p class="danger-zone-note">
                <em>Note: Your account will be deleted if this is the last company associated with it.</em>
              </p>
            </div>
          </div>

          <div class="danger-zone-action">
            <form
              ref="deleteForm"
              @submit.prevent="handleDelete"
              :action="paths.actions.clientSetup"
              method="post">
              <input type="hidden" name="_method" value="delete">

              <!-- Confirmation Input -->
              <div class="confirmation-field" v-if="showDeleteConfirmation">
                <label class="form-label-small">
                  Type <strong>{{ deleteFormData.name || 'DELETE' }}</strong> to confirm:
                </label>
                <CFormInput
                  v-model="deleteConfirmation"
                  placeholder="Type company name to confirm"
                  class="form-input-small mb-3"
                  :class="{ 'is-invalid': confirmationError }"
                />
                <div class="form-error" v-if="confirmationError">
                  {{ confirmationError }}
                </div>
              </div>

              <div class="danger-zone-buttons">
                <CButton
                  v-if="!showDeleteConfirmation"
                  type="button"
                  @click="initiateDelete"
                  class="btn-danger-outline">
                  Delete Company
                </CButton>

                <template v-else>
                  <CButton
                    type="button"
                    @click="cancelDelete"
                    class="btn-secondary-outline">
                    Cancel
                  </CButton>
                  <CButton
                    type="submit"
                    :disabled="!canConfirmDelete"
                    class="btn-danger">
                    <svg class="btn-icon" width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
                      <path fill-rule="evenodd" d="M5 3.25V4H2.75a.75.75 0 000 1.5h.3l.815 8.15A1.5 1.5 0 005.357 15h5.286a1.5 1.5 0 001.492-1.35L12.95 5.5h.3a.75.75 0 000-1.5H11V3.25a2.25 2.25 0 00-2.25-2.25h-1.5A2.25 2.25 0 005 3.25zm2.25-.75a.75.75 0 00-.75.75V4h3V3.25a.75.75 0 00-.75-.75h-1.5zM6.05 6a.75.75 0 01.787.713l.275 5.5a.75.75 0 01-1.498.075l-.275-5.5A.75.75 0 016.05 6zm3.9 0a.75.75 0 01.712.787l-.275 5.5a.75.75 0 01-1.498-.075l.275-5.5a.75.75 0 01.786-.712z" clip-rule="evenodd" />
                    </svg>
                    Permanently Delete
                  </CButton>
                </template>
              </div>
            </form>
          </div>
        </div>
      </div>
    </CContainer>
  </div>
</template>

<script lang="ts" setup>
  import { computed, reactive, ref } from 'vue';
  import { useVuelidate } from '@vuelidate/core';
  import { required } from '@vuelidate/validators';
  import ColorPicker from '@/components/ColorPicker.vue';
  import useAuth from '@/composables/useAuth';

  const { client, paths } = useAuth();

  const form = ref<HTMLFormElement>();
  const formData = reactive({
    name: client.value?.name,
    color: client.value?.color || null
  });

  const deleteForm = ref<HTMLFormElement>();
  const deleteFormData = reactive({
    name: ''
  });
  const showDeleteConfirmation = ref(false);
  const deleteConfirmation = ref('');
  const confirmationError = ref('');

  const isValidHexColor = (value: string | null) => {
    if (!value)
      return true;
    return /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(value);
  };

  const v$ = useVuelidate(rules, formData);

  function rules() {
    return {
      name: { required },
      color: {
        isValidHexColor: {
          $validator: isValidHexColor,
          $message: 'Please enter a valid hex color (e.g., #FF0000)'
        }
      }
    };
  }

  async function handleSubmit() {
    const isValid = await v$.value.$validate();
    if (!isValid)
      return;

    form.value?.$el.submit();
  }

  const canConfirmDelete = computed(() => {
    const expectedText = deleteFormData.name || 'DELETE'
    return deleteConfirmation.value === expectedText.trim()
  });

  const initiateDelete = () => {
    showDeleteConfirmation.value = true
    deleteConfirmation.value = ''
    confirmationError.value = ''
  }

  const cancelDelete = () => {
    showDeleteConfirmation.value = false
    deleteConfirmation.value = ''
    confirmationError.value = ''
  }

  async function handleDelete() {
    const expectedText = deleteFormData.name || 'DELETE';

    if (deleteConfirmation.value.trim() !== expectedText.trim()) {
      confirmationError.value = 'Company name does not match';
      return;
    }

    // Add final confirmation dialog
    const confirmed = window.confirm(
      `Are you absolutely sure you want to delete "${client.value?.name}"? This action cannot be undone.`
    );

    if (confirmed)
      deleteForm.value?.submit()
  }
</script>

<style scoped>
  .danger-zone-card {
    background: #fefefe;
    border: 1px solid #fee2e2;
    border-radius: 8px;
    overflow: hidden;
  }

  .danger-zone-header {
    background: #fef2f2;
    border-bottom: 1px solid #fecaca;
    padding: 1rem 1.5rem;
  }

  .danger-zone-title {
    color: #dc2626;
    font-size: 1.125rem;
    font-weight: 600;
    margin: 0;
  }

  .danger-icon {
    color: #dc2626;
    flex-shrink: 0;
  }

  .danger-zone-content {
    padding: 1.5rem;
    display: flex;
    gap: 2rem;
    align-items: flex-start;
  }

  @media (max-width: 768px) {
    .danger-zone-content {
      flex-direction: column;
      gap: 1.5rem;
    }
  }

  .danger-zone-info {
    flex: 1;
  }

  .danger-zone-action-title {
    color: #374151;
    font-size: 1rem;
    font-weight: 600;
    margin: 0 0 0.5rem 0;
  }

  .danger-zone-description {
    color: #6b7280;
    font-size: 0.875rem;
    line-height: 1.5;
  }

  .danger-zone-list {
    margin: 0.5rem 0;
    padding-left: 1.25rem;
  }

  .danger-zone-list li {
    margin-bottom: 0.25rem;
  }

  .danger-zone-note {
    margin-top: 0.75rem;
    font-size: 0.8125rem;
    color: #9ca3af;
  }

  .danger-zone-action {
    flex-shrink: 0;
    min-width: 200px;
  }

  .confirmation-field {
    margin-bottom: 1rem;
  }

  .form-label-small {
    display: block;
    font-size: 0.875rem;
    font-weight: 500;
    color: #374151;
    margin-bottom: 0.5rem;
  }

  .form-input-small {
    font-size: 0.875rem;
  }

  .danger-zone-buttons {
    display: flex;
    gap: 0.75rem;
    justify-content: flex-end;
  }

  .btn-danger-outline {
    background: transparent;
    border: 1px solid #dc2626;
    color: #dc2626;
    padding: 0.5rem 1rem;
    border-radius: 6px;
    font-size: 0.875rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn-danger-outline:hover {
    background: #dc2626;
    color: white;
  }

  .btn-danger {
    background: #dc2626;
    border: 1px solid #dc2626;
    color: white;
    padding: 0.5rem 1rem;
    border-radius: 6px;
    font-size: 0.875rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .btn-danger:hover:not(:disabled) {
    background: #b91c1c;
    border-color: #b91c1c;
  }

  .btn-danger:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .btn-secondary-outline {
    background: transparent;
    border: 1px solid #d1d5db;
    color: #6b7280;
    padding: 0.5rem 1rem;
    border-radius: 6px;
    font-size: 0.875rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn-secondary-outline:hover {
    background: #f9fafb;
    border-color: #9ca3af;
  }

  .btn-icon {
    flex-shrink: 0;
  }
</style>
