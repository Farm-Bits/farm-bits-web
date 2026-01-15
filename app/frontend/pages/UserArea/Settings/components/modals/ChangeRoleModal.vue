<template>
  <CModal
    :visible="visible"
    @close="handleClose"
    backdrop="static">
    <CModalHeader>
      <CModalTitle>Change User Role</CModalTitle>
    </CModalHeader>
    <CModalBody>
      <div v-if="clientUser" class="mb-4">
        <div class="d-flex align-items-center">
          <div>
            <p class="mb-1">
              Change role for <strong>{{ clientUser.user.name }}</strong>
            </p>
            <small class="text-muted">{{ clientUser.user.email }}</small>
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
    clientUserId: ClientUser['id'];
    userId: ClientUser['id'];
    role: Role;
  };

  const props = defineProps<{
    visible: boolean;
    clientUser: ClientUser | null;
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
          selectedRole.value !== props.clientUser?.role;
  });

  function resetForm() {
    selectedRole.value = props.clientUser?.role || null;
    submissionError.value = '';
    isLoading.value = false;
  }

  function handleClose() {
    resetForm();
    emit('close');
  }

  async function handleSubmit() {
    if (!props.clientUser || !selectedRole.value || !hasRoleChanged.value)
      return;

    isLoading.value = true;

    emit('update', {
      clientUserId: props.clientUser.id,
      userId: props.clientUser.user_id,
      role: selectedRole.value
    }, (success, error) => {
      if (!success && error)
        submissionError.value = error.error;
      isLoading.value = false;
    });
  }

  watch(() => props.clientUser, (newClientUser) => {
    if (newClientUser)
      selectedRole.value = newClientUser.role;
  });

  watch(() => props.visible, (newValue) => {
    if (newValue && props.clientUser)
      selectedRole.value = props.clientUser.role;
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
