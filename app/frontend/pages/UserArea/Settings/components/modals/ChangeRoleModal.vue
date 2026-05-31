<template>
  <CModal
    :visible="visible"
    @close="handleClose"
    backdrop="static">
    <CModalHeader>
      <CModalTitle>Change User Role</CModalTitle>
    </CModalHeader>
    <CModalBody>
      <CAlert
        v-if="companyUser && companyUserHasOtherSites(companyUser)"
        color="info"
        class="mb-3">
        <div class="d-flex">
          <CIcon name="cilInfo" class="me-2 mt-1" />
          <div>
            <strong>Partial View:</strong> This user has access to
            <strong>{{ companyUser.total_sites_count }} site(s)</strong>, but you can only
            modify access for the <strong>{{ companyUser.visible_site_ids.length }} site(s)</strong>
            you can see. Changes here will only affect visible sites.
          </div>
        </div>
      </CAlert>

      <CForm @submit.prevent="handleSubmit">
        <!-- User Info -->
        <CCard color="light" class="mb-4">
          <CCardBody class="p-3">
            <div class="d-flex align-items-center">
              <CIcon name="cilUser" size="xl" class="text-primary me-3" />
              <div>
                <div class="fw-semibold">{{ companyUser?.user.name }}</div>
                <div class="text-medium-emphasis small">{{ companyUser?.user.email }}</div>
              </div>
            </div>
          </CCardBody>
        </CCard>

        <CAlert v-if="errors.submission" color="danger" class="d-flex align-items-center mb-3">
          <CIcon name="cilWarning" class="me-2" />
          <div>{{ errors.submission }}</div>
        </CAlert>

        <!-- New Role Selection -->
        <div class="mb-3">
          <CFormLabel>New Role *</CFormLabel>
          <div class="mt-2">
            <CFormCheck
              v-for="(roleData, roleId) in availableRoles"
              type="radio"
              class="mb-4"
              :key="roleId"
              :id="`role-${roleId}`"
              :label="`${roleData.name} - ${roleData.description}`"
              :value="roleId"
              :disabled="roleId === companyUser?.role"
              v-model="formData.role" />
          </div>
          <CFormFeedback v-if="errors.role" invalid>
            {{ errors.role }}
          </CFormFeedback>
        </div>

        <!-- Site Access Management -->
        <div v-if="selectedRoleNeedsSites" class="mb-3">
          <CFormLabel for="siteSelection">
            Site Access *
          </CFormLabel>
          <CFormText class="d-block mb-2">
            Select all sites this user should have access to with this role.
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
        :disabled="!hasChanges || isLoading"
        @click="handleSubmit">
        <CSpinner v-if="isLoading" size="sm" class="me-2" />
        {{ isLoading ? 'Updating...' : 'Update Role' }}
      </CButton>
    </CModalFooter>
  </CModal>
</template>

<script lang="ts" setup>
  import { ref, reactive, computed, watch } from 'vue';
  import axios from 'axios';
  import { ROLES, type Role } from '@/types/permissions';
  import type { CompanyUser } from '../types/invitation';
  import useAuth from '@/composables/useAuth';
  import { useApiCall } from '@/composables/useApi';
  import type { Site } from '@/types/location';

  const props = defineProps<{
    visible: boolean;
    companyUser: CompanyUser | null;
  }>();

  const emit = defineEmits<{
    (e: 'close'): void;
    (e: 'update', updatedCompanyUser: CompanyUser): void;
  }>();

  const { currentRole, accessibleSites, routePath } = useAuth();
  const { execute } = useApiCall();

  const formData = reactive({
    role: 'viewer' as Role,
    site_ids: [] as Site['id'][]
  });

  const errors = reactive({
    submission: '',
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

  const hasChanges = computed(() => {
    const roleChanged = formData.role !== props.companyUser?.role;
    const siteAccessChanged = !arraysEqual(
      formData.site_ids.sort(),
      (props.companyUser?.visible_site_ids || []).sort()
    );
    return roleChanged || siteAccessChanged;
  });

  function arraysEqual<T>(a: T[], b: T[]) {
    if (a.length !== b.length)
      return false;
    return a.every((val, idx) => val === b[idx]);
  }

  function companyUserHasOtherSites(companyUser: CompanyUser) {
    return companyUser.total_sites_count > companyUser.visible_site_ids.length;
  }

  function validateForm() {
    errors.role = '';
    errors.site_ids = '';

    if (!formData.role)
      errors.role = 'Please select a role';

    if (selectedRoleNeedsSites.value) {
      if (formData.site_ids.length === 0)
        errors.site_ids = 'Please select at least one site for this role';
      else if (formData.site_ids.some((id) => !accessibleSites.value?.some((site) => site.id === id)))
        errors.site_ids = 'One or more selected sites are invalid';
    }

    return !errors.role && !errors.site_ids;
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
    formData.role = props.companyUser?.role || 'viewer';
    formData.site_ids = [...(props.companyUser?.visible_site_ids || [])];

    errors.submission = '';
    errors.role = '';
    errors.site_ids = '';

    isLoading.value = false;
  }

  function handleClose() {
    resetForm();
    emit('close');
  }

  async function handleSubmit() {
    if (!props.companyUser)
      return;

    if (!validateForm())
      return;

    isLoading.value = true;

    const body = {
      company_user: {
        id: props.companyUser.id,
        user_id: props.companyUser.user.id,
        role: formData.role,
        site_ids: selectedRoleNeedsSites.value ? formData.site_ids : undefined
      }
    };
    const url = routePath('company_users_update', { id: props.companyUser.id });
    const { success, data, error } = await execute<CompanyUser>(
      () => axios.patch(url, body),
      {
        showSuccessToast: true,
        successMessage: 'User role updated successfully'
      }
    );

    if (success)
      emit('update', data);
    else
      errors.submission = error.error || 'An error occurred while updating the user role';

    isLoading.value = false;
  }

  watch(() => props.visible, (newValue) => {
    if (newValue)
      resetForm();
  });

  watch(() => formData.role, (newRole, oldRole) => {
    if (!oldRole)
      return;

    const oldRoleNeedsSites = ROLES[oldRole]?.siteSpecific;
    const newRoleNeedsSites = ROLES[newRole]?.siteSpecific;

    // Clear sites when switching to non-site-specific role
    if (oldRoleNeedsSites && !newRoleNeedsSites) {
      formData.site_ids = [];
      errors.site_ids = '';
    }

    // Restore sites when switching to site-specific role
    if (!oldRoleNeedsSites && newRoleNeedsSites)
      formData.site_ids = [...(props.companyUser?.visible_site_ids || [])];
  });
</script>

<style scoped>
</style>
