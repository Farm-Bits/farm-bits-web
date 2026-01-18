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
            v-model="form.email"
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
              v-model="form.role" />
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
                v-for="site in sites"
                :key="site.id"
                :id="`site-${site.id}`"
                :label="site.name"
                :value="String(site.id)"
                :checked="form.site_ids.includes(site.id)"
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
  import { type ApiError } from '@/composables/useApi';
  import { ROLES, type Role } from '@/types/permissions';
  import type { Site } from '@/types/location';
  import useAuth from '@/composables/useAuth';
  import type { InvitationData } from '../types/invitation';

  const props = defineProps<{
    visible: boolean;
  }>();

  const emit = defineEmits<{
    (e: 'close'): void;
    (
      e: 'invite',
      data: InvitationData,
      callback?: (success: boolean, error?: ApiError) => void
    ): void;
  }>();

  const { role, sites } = useAuth();

  const form = reactive({
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
    if (!role.value)
      return ROLES;

    const currentLevel = ROLES[role.value].level;
    const filteredRoles: Partial<typeof ROLES> = {};

    Object.entries(ROLES).forEach(([roleId, roleData]) => {
      if (roleData.level <= currentLevel)
        filteredRoles[roleId as Role] = roleData;
    });

    return filteredRoles as typeof ROLES;
  });

  const selectedRoleNeedsSites = computed(() => {
    return ROLES[form.role]?.siteSpecific || false;
  });

  const isFormValid = computed(() => {
    const hasEmail = form.email.trim() !== '' && isValidEmail(form.email);
    const hasRole = !!form.role;
    const hasSitesIfNeeded = !selectedRoleNeedsSites.value || form.site_ids.length > 0;
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

    if (!form.email.trim())
      errors.email = 'Email address is required';
    else if (!isValidEmail(form.email))
      errors.email = 'Please enter a valid email address';

    if (!form.role)
      errors.role = 'Please select a role';

    if (selectedRoleNeedsSites.value) {
      if (form.site_ids.length === 0)
        errors.site_ids = 'Please select at least one site for this role';
      else if (form.site_ids.some((id) => !sites.value?.some((site) => site.id === id)))
        errors.site_ids = 'One or more selected sites are invalid';
    }

    return !errors.email && !errors.role && !errors.site_ids;
  }

  function toggleSite(siteId: number) {
    const index = form.site_ids.indexOf(siteId);
    if (index > -1)
      form.site_ids.splice(index, 1);
    else
      form.site_ids.push(siteId);

    if (form.site_ids.length > 0)
      errors.site_ids = '';
  }

  function resetForm() {
    form.email = '';
    form.role = 'viewer';
    form.site_ids = [];

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

    const invitationData: InvitationData = {
      email: form.email.trim(),
      role: form.role,
      site_ids: selectedRoleNeedsSites.value ? form.site_ids : undefined
    };

    emit(
      'invite',
      invitationData,
      (success, error) => {
        if (!success && error)
          errors.submission = error.error;

        isLoading.value = false;
      }
    );
  }

  watch(() => props.visible, (newValue) => {
    if (newValue)
      resetForm();
  });

  watch(() => selectedRoleNeedsSites.value, (needsSites, previousNeedsSites) => {
    if (!needsSites && previousNeedsSites) {
      form.site_ids = [];
      errors.site_ids = '';
    }
  });
</script>

<style scoped>
</style>
