<template>
  <div class="d-flex justify-content-center align-items-center min-vh-100 px-3">
    <CCard class="otp-card shadow-sm">
      <CCardBody class="p-4">
        <div class="text-center mb-4">
          <CIcon name="cilShieldAlt" size="3xl" class="text-primary mb-3" />
          <h4 class="mb-2">Two-Factor Authentication</h4>
          <p class="text-muted mb-0">
            Enter the 6-digit verification code sent to <strong>{{ otpDestination }}</strong>.
          </p>
        </div>

        <ErrorMessages class="mb-3" />

        <div class="mb-3">
          <CFormLabel for="otp-input">Verification code</CFormLabel>
          <CFormInput
            id="otp-input"
            v-model="verifyForm.otp"
            type="text"
            inputmode="numeric"
            pattern="[0-9]*"
            maxlength="6"
            autocomplete="one-time-code"
            autofocus
            placeholder="000000"
            class="otp-input"
            :invalid="!!verifyForm.errors.otp"
            @input="onOtpInput"
            @keyup.enter="verify" />
        </div>

        <div class="d-grid gap-2 mb-3">
          <CButton
            color="primary"
            :disabled="!isOtpComplete || verifyForm.processing"
            @click="verify">
            <CIcon name="cilCheck" class="me-2" />
            {{ verifyForm.processing ? 'Verifying…' : 'Verify' }}
          </CButton>
        </div>

        <div class="text-center">
          <small class="text-muted d-block mb-2">Didn't receive a code?</small>
          <CButton
            color="secondary"
            variant="ghost"
            size="sm"
            :disabled="resendForm.processing || resendCooldown > 0"
            @click="resend">
            <CIcon name="cilReload" class="me-1" />
            <span v-if="resendCooldown > 0">Resend in {{ resendCooldown }}s</span>
            <span v-else-if="resendForm.processing">Sending…</span>
            <span v-else>Resend code</span>
          </CButton>
        </div>

        <hr class="my-4" />

        <div class="text-center">
          <a
            href="#"
            class="text-decoration-none text-muted small"
            @click.prevent="signOut">
            <CIcon name="cilArrowLeft" class="me-1" />
            Sign in with a different account
          </a>
        </div>
      </CCardBody>
    </CCard>
  </div>
</template>

<script lang="ts" setup>
  import { computed, onUnmounted, ref } from 'vue';
  import { router, useForm, usePage } from '@inertiajs/vue3';
  import useAuth from '@/composables/useAuth';

  const { paths } = useAuth();
  const page = usePage<{
    otp_destination?: string;
  }>();

  const verifyForm = useForm({ otp: '' });
  const resendForm = useForm({});

  const RESEND_COOLDOWN_SECONDS = 30;
  const resendCooldown = ref(0);
  let cooldownInterval: ReturnType<typeof setInterval> | null = null;

  const isOtpComplete = computed(() => verifyForm.otp.length === 6);
  const otpDestination = computed(() => page.props.otp_destination ?? 'your registered contact');

  function onOtpInput(event: Event) {
    const target = event.target as HTMLInputElement;
    const cleaned = target.value.replace(/\D/g, '').slice(0, 6);
    verifyForm.otp = cleaned;
    target.value = cleaned;
  }

  function verify() {
    if (!isOtpComplete.value)
      return;

    verifyForm.post(paths.value.actions.verifyOtp, {
      preserveScroll: true,
      onError: () => {
        verifyForm.otp = '';
      }
    });
  }

  function resend() {
    if (resendCooldown.value > 0 || resendForm.processing)
      return;

    resendForm.post(paths.value.actions.resendOtp, {
      preserveScroll: true,
      onSuccess: () => startResendCooldown()
    });
  }

  function startResendCooldown() {
    resendCooldown.value = RESEND_COOLDOWN_SECONDS;
    cooldownInterval = setInterval(() => {
      resendCooldown.value -= 1;
      if (resendCooldown.value <= 0 && cooldownInterval) {
        clearInterval(cooldownInterval);
        cooldownInterval = null;
      }
    }, 1000);
  }

  function signOut() {
    router.delete(paths.value.actions.signOut);
  }

  onUnmounted(() => {
    if (cooldownInterval)
      clearInterval(cooldownInterval);
  });
</script>

<style scoped>
  .otp-card {
    width: 100%;
    max-width: 420px;
  }

  .otp-input {
    font-size: 1.5rem;
    text-align: center;
    letter-spacing: 0.5rem;
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  }

  .form-error {
    color: #dc3545;
    font-size: 0.875rem;
    margin-top: 0.25rem;
  }
</style>
