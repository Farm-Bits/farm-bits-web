<template>
  <CModal
    :visible="visible"
    @close="handleClose"
    backdrop="static">
    <CModalHeader>
      <CModalTitle>Change User Role</CModalTitle>
    </CModalHeader>
    <CModalBody>
      <CForm @submit.prevent="handleSubmit">
        <!-- User Info -->
        <CCard color="light" class="mb-4">
          <CCardBody class="p-3">
            <div class="d-flex align-items-center">
              <CIcon name="cilUser" size="xl" class="text-primary me-3" />
              <div>
                <div class="fw-semibold">{{ clientUser?.user.name }}</div>
                <div class="text-medium-emphasis small">{{ clientUser?.user.email }}</div>
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
              :disabled="roleId === clientUser?.role"
              v-model="form.role" />
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
  import { ROLES, type Role } from '@/types/permissions';
  import type { ChangeRoleData, ClientUser } from '../types/invitation';
  import useAuth from '@/composables/useAuth';
  import type { ApiError } from '@/composables/useApi';
  import type { Site } from '@/types/location';

  const props = defineProps<{
    visible: boolean;
    clientUser: ClientUser | null;
  }>();

  const emit = defineEmits<{
    (e: 'close'): void;
    (
      e: 'update',
      changeRoleData: ChangeRoleData,
      callback?: (success: boolean, error?: ApiError) => void
    ): void;
  }>();

  const { role, sites } = useAuth();

  const form = reactive({
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

  const hasChanges = computed(() => {
    const roleChanged = form.role !== props.clientUser?.role;
    const siteAccessChanged = !arraysEqual(
      form.site_ids.sort(),
      (props.clientUser?.site_ids || []).sort()
    );
    return roleChanged || siteAccessChanged;
  });

  function arraysEqual<T>(a: T[], b: T[]): boolean {
    if (a.length !== b.length)
      return false;
    return a.every((val, idx) => val === b[idx]);
  }

  function validateForm(): boolean {
    errors.role = '';
    errors.site_ids = '';

    if (!form.role)
      errors.role = 'Please select a role';

    if (selectedRoleNeedsSites.value) {
      if (form.site_ids.length === 0)
        errors.site_ids = 'Please select at least one site for this role';
      else if (form.site_ids.some((id) => !sites.value?.some((site) => site.id === id)))
        errors.site_ids = 'One or more selected sites are invalid';
    }

    return !errors.role && !errors.site_ids;
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
    form.role = props.clientUser?.role || 'viewer';
    form.site_ids = [...(props.clientUser?.site_ids || [])];

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
    if (!validateForm())
      return;

    isLoading.value = true;

    const updateData: ChangeRoleData = {
      role: form.role,
      site_ids: selectedRoleNeedsSites.value ? form.site_ids : undefined
    };

    emit(
      'update',
      updateData,
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

  watch(() => form.role, (newRole, oldRole) => {
    if (!oldRole)
      return;

    const oldRoleNeedsSites = ROLES[oldRole]?.siteSpecific;
    const newRoleNeedsSites = ROLES[newRole]?.siteSpecific;

    // Clear sites when switching to non-site-specific role
    if (oldRoleNeedsSites && !newRoleNeedsSites) {
      form.site_ids = [];
      errors.site_ids = '';
    }

    // Restore sites when switching to site-specific role
    if (!oldRoleNeedsSites && newRoleNeedsSites) {
      form.site_ids = [...(props.clientUser?.site_ids || [])];
    }
  });
</script>

<style scoped>
</style>
