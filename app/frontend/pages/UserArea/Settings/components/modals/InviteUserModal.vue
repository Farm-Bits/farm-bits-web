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
        <CAlert v-if="errors.submission" color="danger" class="d-flex align-items-center mb-3">
          <CIcon name="cilWarning" class="me-2" />
          <div>{{ errors.submission }}</div>
        </CAlert>

        <!-- Email Input -->
        <div class="mb-3">
          <CFormLabel for="inviteEmail">Email Address *</CFormLabel>
          <CFormInput
            id="inviteEmail"
            name="email"
            type="email"
            placeholder="Enter email address"
            required
            v-model="formData.email"
            :invalid="!!errors.email" />
          <CFormFeedback v-if="errors.email" invalid>
            {{ errors.email }}
          </CFormFeedback>
        </div>

        <!-- Role Selection -->
        <div class="mb-3">
          <CFormLabel>Role *</CFormLabel>
          <div class="mt-2">
            <CFormCheck
              v-for="(roleData, roleId) in availableRoles"
              type="radio"
              class="mb-2"
              :key="roleId"
              :id="`role-${roleId}`"
              :label="`${roleData.name} - ${roleData.description}`"
              :value="roleId"
              v-model="formData.role" />
          </div>
          <CFormFeedback v-if="errors.role" invalid>
            {{ errors.role }}
          </CFormFeedback>
        </div>

        <!-- Site Selection (for site-specific roles) -->
        <div v-if="selectedRoleNeedsSites" class="mb-3">
          <CFormLabel for="siteSelection">
            Site Access *
          </CFormLabel>
          <CFormText class="d-block mb-2">
            Select which sites this user will have access to
          </CFormText>

          <CCard class="border">
            <CCardBody class="p-3" style="max-height: 300px; overflow-y: auto;">
              <CFormCheck
                v-for="site in accessibleSites"
                :key="site.id"
                :id="`site-${site.id}`"
                :label="site.name"
                :value="String(site.id)"
                :checked="formData.site_ids.includes(site.id)"
                @change="toggleSite(site.id)" />
            </CCardBody>
          </CCard>
          <CFormFeedback v-if="errors.site_ids" invalid>
            {{ errors.site_ids }}
          </CFormFeedback>
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
  import axios from 'axios';
  import { ROLES, type Role } from '@/types/permissions';
  import useAuth from '@/composables/useAuth';
  import { useApiCall } from '@/composables/useApi';
  import type { Invitation } from '../types/invitation';

  const props = defineProps<{
    visible: boolean;
  }>();

  const emit = defineEmits<{
    (e: 'close'): void;
    (e: 'invite', data: Invitation): void;
  }>();

  const { currentRole, accessibleSites, routePath } = useAuth();
  const { execute } = useApiCall();

  const formData = reactive({
    email: '',
    role: 'viewer' as Role,
    site_ids: [] as number[]
  });

  const errors = reactive({
    submission: '',
    email: '',
    role: '',
    site_ids: ''
  });

  const isLoading = ref(false);

  const availableRoles = computed(() => {
    if (!currentRole.value)
      return ROLES;

    const currentLevel = ROLES[currentRole.value].level;
    const filteredRoles: Partial<typeof ROLES> = {};

    Object.entries(ROLES).forEach(([roleId, roleData]) => {
      if (roleData.level <= currentLevel)
        filteredRoles[roleId as Role] = roleData;
    });

    return filteredRoles as typeof ROLES;
  });

  const selectedRoleNeedsSites = computed(() => {
    return ROLES[formData.role]?.siteSpecific || false;
  });

  const isFormValid = computed(() => {
    const hasEmail = formData.email.trim() !== '' && isValidEmail(formData.email);
    const hasRole = !!formData.role;
    const hasSitesIfNeeded = !selectedRoleNeedsSites.value || formData.site_ids.length > 0;
    const noErrors = !errors.email && !errors.role && !errors.site_ids;

    return hasEmail && hasRole && hasSitesIfNeeded && noErrors;
  });

  function isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  function validateForm(): boolean {
    errors.email = '';
    errors.role = '';
    errors.site_ids = '';

    if (!formData.email.trim())
      errors.email = 'Email address is required';
    else if (!isValidEmail(formData.email))
      errors.email = 'Please enter a valid email address';

    if (!formData.role)
      errors.role = 'Please select a role';

    if (selectedRoleNeedsSites.value) {
      if (formData.site_ids.length === 0)
        errors.site_ids = 'Please select at least one site for this role';
      else if (formData.site_ids.some((id) => !accessibleSites.value?.some((site) => site.id === id)))
        errors.site_ids = 'One or more selected sites are invalid';
    }

    return !errors.email && !errors.role && !errors.site_ids;
  }

  function toggleSite(siteId: number) {
    const index = formData.site_ids.indexOf(siteId);
    if (index > -1)
      formData.site_ids.splice(index, 1);
    else
      formData.site_ids.push(siteId);

    if (formData.site_ids.length > 0)
      errors.site_ids = '';
  }

  function resetForm() {
    formData.email = '';
    formData.role = 'viewer';
    formData.site_ids = [];

    errors.submission = '';
    errors.email = '';
    errors.role = '';
    errors.site_ids = '';

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

    const body = {
      invitation: {
        email: formData.email.trim(),
        role: formData.role,
        site_ids: selectedRoleNeedsSites.value ? formData.site_ids : undefined
      }
    };
    const { success, data, error } = await execute<Invitation>(
      () => axios.post(routePath('invitations_create'), body),
      {
        showSuccessToast: true,
        successMessage: 'Invitation sent successfully'
      }
    );

    if (success)
      emit('invite', data);
    else
      errors.submission = error.error || 'An error occurred while sending the invitation';

    isLoading.value = false;
  }

  watch(() => props.visible, (newValue) => {
    if (newValue)
      resetForm();
  });

  watch(() => selectedRoleNeedsSites.value, (needsSites, previousNeedsSites) => {
    if (!needsSites && previousNeedsSites) {
      formData.site_ids = [];
      errors.site_ids = '';
    }
  });
</script>

<style scoped>
</style>
