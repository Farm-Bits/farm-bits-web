<template>
  <div class="px-4">
    <ErrorMessages class="mb-2" />

    <!-- Two-Factor Authentication -->
    <div class="row align-items-center py-3 border-bottom">
      <div class="col-md-3">
        <label class="form-label mb-0 fw-medium">Two-Factor Authentication</label>
      </div>
      <div class="col-md-6">
        <div class="d-flex align-items-center gap-2">
          <CBadge :color="otpEnabled ? 'success' : 'secondary'">
            {{ otpEnabled ? 'Enabled' : 'Disabled' }}
          </CBadge>
          <small v-if="companyRequires2fa && otpEnabled" class="text-muted">
            <CIcon name="cilLockLocked" class="me-1" />
            Required by your company
          </small>
        </div>
        <small class="text-muted d-block mt-2">
          Adds a one-time code challenge after password sign-in.
        </small>
      </div>
      <div v-if="permissions?.two_factors.update" class="col-md-3 text-end">
        <CButton
          v-if="!otpEnabled"
          color="primary"
          @click="openToggleModal(true)">
          <CIcon name="cilShieldAlt" class="me-1" />
          Enable
        </CButton>
        <CButton
          v-else
          color="danger"
          variant="outline"
          :disabled="companyRequires2fa"
          @click="openToggleModal(false)">
          <CIcon name="cilX" class="me-1" />
          Disable
        </CButton>
      </div>
    </div>

    <!-- Active Sessions -->
    <div class="row py-3">
      <div class="col-md-3">
        <label class="form-label mb-0 fw-medium">Active Sessions</label>
        <small class="text-muted d-block mt-2">
          Devices currently signed in to your account.
        </small>
      </div>
      <div class="col-md-9">
        <CCard>
          <CCardHeader class="d-flex justify-content-between align-items-center">
            <h6 class="mb-0">All sessions</h6>
            <CButton
              v-if="permissions?.sessions.destroy_all"
              color="danger"
              variant="outline"
              size="sm"
              @click="revokeAll"
              :disabled="otherSessionsCount === 0">
              Sign out everywhere else
            </CButton>
          </CCardHeader>

          <CCardBody class="p-0">
            <CListGroup flush>
              <CListGroupItem
                v-for="session in sessions"
                :key="session.id"
                class="d-flex justify-content-between align-items-center">
                <div>
                  <div class="d-flex align-items-center gap-2">
                    <strong>{{ session.client_name }}</strong>
                    <CBadge v-if="session.is_current_session" color="success">
                      This device
                    </CBadge>
                    <CBadge v-if="session.transport === 'mobile'" color="info">
                      Mobile
                    </CBadge>
                    <CBadge v-if="session.remembered" color="secondary">
                      Remembered
                    </CBadge>
                  </div>
                  <div class="text-muted small mt-1">
                    {{ session.ip_address }} · last active {{ formatRelative(session.last_seen_at) }}
                  </div>
                </div>
                <CButton
                  v-if="permissions?.sessions.destroy"
                  color="danger"
                  variant="ghost"
                  size="sm"
                  @click="revoke(session)">
                  {{ session.is_current_session ? 'Sign out' : 'Revoke' }}
                </CButton>
              </CListGroupItem>

              <CListGroupItem v-if="sessions.length === 0" class="text-center text-muted py-4">
                No active sessions found.
              </CListGroupItem>
            </CListGroup>
          </CCardBody>
        </CCard>
      </div>
    </div>

    <!-- 2FA Toggle Modal -->
    <CModal
      :visible="showToggleModal"
      @close="closeToggleModal"
      backdrop="static">
      <CModalHeader>
        <CModalTitle>
          {{ pendingEnable ? 'Enable' : 'Disable' }} Two-Factor Authentication
        </CModalTitle>
      </CModalHeader>
      <CModalBody>
        <p class="mb-3" v-if="pendingEnable">
          Once enabled, you'll be asked for a one-time code each time you sign in.
        </p>
        <p class="mb-3" v-else>
          Disabling 2FA reduces the security of your account.
        </p>

        <div class="mb-3">
          <CFormLabel>Enter your current password to confirm:</CFormLabel>
          <CFormInput
            v-model="toggleForm.current_password"
            type="password"
            placeholder="Current password"
            :invalid="!!toggleForm.errors.current_password"
            @keyup.enter="submitToggle"
            class="mb-2" />
          <div class="form-error" v-if="toggleForm.errors.current_password">
            {{ toggleForm.errors.current_password }}
          </div>
        </div>
      </CModalBody>
      <CModalFooter>
        <CButton color="secondary" @click="closeToggleModal">
          Cancel
        </CButton>
        <CButton
          :color="pendingEnable ? 'primary' : 'danger'"
          :disabled="!toggleForm.current_password || toggleForm.processing"
          @click="submitToggle">
          {{ pendingEnable ? 'Enable 2FA' : 'Disable 2FA' }}
        </CButton>
      </CModalFooter>
    </CModal>
  </div>
</template>

<script lang="ts" setup>
  import { computed, ref } from 'vue';
  import { router, usePage, useForm } from '@inertiajs/vue3';
  import useAuth from '@/composables/useAuth';
  import usePermissions from '@/composables/usePermissions';

  type Session = {
    id: number;
    transport: 'web' | 'mobile';
    client_name: string;
    ip_address: string;
    last_seen_at: string;
    expires_at: string;
    is_current_session: boolean;
    remembered: boolean;
  };

  const { paths, currentUser, currentCompany } = useAuth();
  const { permissions } = usePermissions();
  const page = usePage<{ sessions?: Session[] }>();

  const sessions = computed<Session[]>(() => page.props.sessions ?? []);
  const otherSessionsCount = computed(() => sessions.value.filter(s => !s.is_current_session).length);
  const otpEnabled = computed(() => !!currentUser.value?.otp_enabled_at);
  const companyRequires2fa = computed(() => !!currentCompany.value?.require_2fa);

  const showToggleModal = ref(false);
  const pendingEnable = ref(false);

  // One persistent form instance so errors from the redirect (inertia: { errors: {...} })
  // populate toggleForm.errors automatically. Inertia auto-applies preserveState
  // when the response carries errors, so the modal stays mounted and visible.
  const toggleForm = useForm({
    current_password: '',
    enabled: false
  });

  function openToggleModal(enable: boolean) {
    pendingEnable.value = enable;
    toggleForm.reset();
    toggleForm.clearErrors();
    toggleForm.enabled = enable;
    showToggleModal.value = true;
  }

  function closeToggleModal() {
    showToggleModal.value = false;
    toggleForm.reset();
    toggleForm.clearErrors();
  }

  function submitToggle() {
    if (!toggleForm.current_password)
      return;

    toggleForm.put(paths.value.actions.twoFactor, {
      preserveScroll: true,
      onSuccess: () => closeToggleModal()
      // No onError needed: Inertia preserves state automatically when errors
      // are present, so the modal stays open and toggleForm.errors populates.
    });
  }

  function formatRelative(iso: string) {
    const date = new Date(iso);
    const seconds = Math.floor((Date.now() - date.getTime()) / 1000);

    if (seconds < 60)
      return 'just now';

    if (seconds < 3600)
      return `${Math.floor(seconds / 60)}m ago`;

    if (seconds < 86400)
      return `${Math.floor(seconds / 3600)}h ago`;

    return `${Math.floor(seconds / 86400)}d ago`;
  }

  function revoke(session: Session) {
    const message = session.is_current_session
      ? 'Sign out of this session?'
      : `Sign out ${session.client_name}?`;

    if (!confirm(message))
      return;

    router.delete(paths.value.actions.deleteSession(session.id), {
      preserveScroll: true,
      onSuccess: () => router.reload({ only: ['sessions'] })
    });
  }

  function revokeAll() {
    if (!confirm('Sign out of all other sessions? This cannot be undone.'))
      return;

    router.delete(paths.value.actions.deleteAllSessions, {
      preserveScroll: true,
      onSuccess: () => router.reload({ only: ['sessions'] })
    });
  }
</script>

<style scoped>
  .form-error {
    color: #dc3545;
    font-size: 0.875rem;
    margin-top: 0.25rem;
  }
</style>
