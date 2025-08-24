<template>
  <CModal
    :visible="visible"
    @close="handleClose"
    backdrop="static">
    <CModalHeader>
      <CModalTitle>Invite User</CModalTitle>
    </CModalHeader>
    <CModalBody>
      <CForm @submit.prevent="handleSubmit">
        <CFormFeedback v-if="errors.submission" :invalid="true" class="mb-3">
          {{ errors.submission }}
        </CFormFeedback>

        <div class="mb-3">
          <CFormLabel for="inviteEmail">Email Address *</CFormLabel>
          <CFormInput
            id="inviteEmail"
            name="email"
            type="email"
            placeholder="Enter email address"
            required
            v-model="form.email"
            :invalid="!!errors.email" />
          <CFormText v-if="errors.email" class="text-danger">
            {{ errors.email }}
          </CFormText>
        </div>

        <div class="mb-3">
          <CFormLabel>Role *</CFormLabel>
          <div class="mt-2">
            <CFormCheck
              v-for="role in roles"
              type="radio"
              class="mb-2 ml-6"
              :key="role.id"
              :id="`role-${role.id}`"
              :label="`${role.name} - ${role.description}`"
              :value="role.id"
              v-model="form.role" />
            <CFormText v-if="errors.role" class="text-danger">
              {{ errors.role }}
            </CFormText>
          </div>
        </div>
      </CForm>
    </CModalBody>
    <CModalFooter>
      <CButton
        color="secondary"
        @click="handleClose">
        Cancel
      </CButton>
      <CButton
        color="primary"
        :disabled="!isFormValid || isLoading"
        @click="handleSubmit">
        <CSpinner v-if="isLoading" size="sm" class="me-2" />
        {{ isLoading ? 'Sending...' : 'Send Invitation' }}
      </CButton>
    </CModalFooter>
  </CModal>
</template>

<script lang="ts" setup>
  import { ref, reactive, computed, watch } from 'vue';
  import { type Role } from '../types/user_invitation';
  import { type ApiError } from '@/composables/useApi';

  export type InvitationData = {
    email: string;
    role: Role['id'];
  };

  const props = defineProps<{
    visible: boolean;
    roles: Role[];
  }>();
  const emit = defineEmits<{
    (e: 'close'): void;
    (
      e: 'invite',
      data: InvitationData,
      callback?: (success: boolean, error?: ApiError) => void
    ): void;
  }>();

  const form = reactive({
    email: '',
    role: 'viewer' as Role['id']
  });
  const errors = reactive({
    submission: '',
    email: '',
    role: ''
  });

  const isLoading = ref(false);

  const isFormValid = computed(() => {
    return form.email.trim() !== '' &&
          form.role &&
          isValidEmail(form.email) &&
          !errors.email &&
          !errors.role;
  });

  function isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  function validateForm() {
    errors.email = '';
    errors.role = '';

    if (!form.email.trim())
      errors.email = 'Email address is required';
    else if (!isValidEmail(form.email))
      errors.email = 'Please enter a valid email address';

    if (!form.role)
      errors.role = 'Please select a role';

    return !errors.email && !errors.role;
  }

  function resetForm() {
    form.email = '';
    form.role = 'viewer';

    errors.submission = '';
    errors.email = '';
    errors.role = '';

    isLoading.value = false;
  }

  function handleClose() {
    resetForm();
    emit('close');
  }

  async function handleSubmit() {
    if (!validateForm())
      return;

    isLoading.value = true;

    emit('invite', {
      email: form.email.trim(),
      role: form.role
    }, (success, error) => {
      if (!success && error)
        errors.submission = error.error;
      isLoading.value = false;
    });
  }

  watch(() => props.visible, (newValue) => {
    if (!newValue)
      resetForm();
  });
</script>

<style scoped>
  .form-check {
    padding: 0.5rem 0;
  }

  .form-check-label {
    font-weight: 500;
  }
</style>
