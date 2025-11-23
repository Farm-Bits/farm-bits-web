<template>
  <CModal
    :visible="visible"
    @close="handleClose"
    backdrop="static">
    <CModalHeader>
      <CModalTitle>Change User Role</CModalTitle>
    </CModalHeader>
    <CModalBody>
      <div v-if="user" class="mb-4">
        <div class="d-flex align-items-center">
          <div>
            <p class="mb-1">
              Change role for <strong>{{ user.name }}</strong>
            </p>
            <small class="text-muted">{{ user.email }}</small>
          </div>
        </div>
      </div>

      <CFormFeedback v-if="submissionError" :invalid="true" class="mb-3">
        {{ submissionError }}
      </CFormFeedback>

      <div class="mb-3">
        <CFormLabel>Select New Role</CFormLabel>
        <div class="mt-2">
          <CFormCheck
            v-for="(role, roleId) in ROLES"
            type="radio"
            class="mb-2 ml-6"
            v-model="selectedRole"
            :key="roleId"
            :id="`change-role-${roleId}`"
            :label="`${role.name} - ${role.description}`"
            :value="roleId" />
        </div>
      </div>
    </CModalBody>
    <CModalFooter>
      <CButton
        color="secondary"
        @click="handleClose">
        Cancel
      </CButton>
      <CButton
        color="primary"
        :disabled="!hasRoleChanged || isLoading"
        @click="handleSubmit">
        <CSpinner v-if="isLoading" size="sm" class="me-2" />
        {{ isLoading ? 'Updating...' : 'Update Role' }}
      </CButton>
    </CModalFooter>
  </CModal>
</template>

<script lang="ts" setup>
  import { ref, computed, watch } from 'vue';
  import { ROLES, type Role } from '@/types/permissions';
  import { type ClientUser } from '../types/invitation';
  import { type ApiError } from '@/composables/useApi';

  export type ChangeRoleData = {
    userId: ClientUser['id'];
    role: Role;
  };

  const props = defineProps<{
    visible: boolean;
    user: ClientUser | null;
  }>();
  const emit = defineEmits<{
    (e: 'close'): void;
    (
      e: 'update',
      data: ChangeRoleData,
      callback?: (success: boolean, error?: ApiError) => void
    ): void;
  }>();

  const selectedRole = ref<Role | null>(null);
  const submissionError = ref('');
  const isLoading = ref(false);

  const hasRoleChanged = computed(() => {
    return selectedRole.value !== null &&
          selectedRole.value !== props.user?.role;
  });

  function resetForm() {
    selectedRole.value = props.user?.role || null;
    submissionError.value = '';
    isLoading.value = false;
  }

  function handleClose() {
    resetForm();
    emit('close');
  }

  async function handleSubmit() {
    if (!props.user || !selectedRole.value || !hasRoleChanged.value)
      return;

    isLoading.value = true;

    emit('update', {
      userId: props.user.id,
      role: selectedRole.value
    }, (success, error) => {
      if (!success && error)
        submissionError.value = error.error;
      isLoading.value = false;
    });
  }

  watch(() => props.user, (newUser) => {
    if (newUser)
      selectedRole.value = newUser.role;
  });

  watch(() => props.visible, (newValue) => {
    if (newValue && props.user)
      selectedRole.value = props.user.role;
    else if (!newValue)
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

  .alert ul {
    padding-left: 1rem;
  }
</style>
