<template>
  <div class="auth-container">
    <div class="auth-card-narrow">
      <div class="auth-card">
        <!-- Header -->
        <div class="auth-header">
          <div class="auth-icon-primary">
            <svg class="auth-icon-svg" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m0 0a2 2 0 012 2m-2-2h-6m6 0v.01M9 20H7a2 2 0 01-2-2V6a2 2 0 012-2h2m4 0h2a2 2 0 012 2v12a2 2 0 01-2 2h-2m-4 0h2m-2 0V10m0-6h2"></path>
            </svg>
          </div>
          <h2 class="auth-title">Reset Password</h2>
          <p class="auth-subtitle">Create a new secure password for your account.</p>
        </div>

        <FlashMessages class="mb-6" />

        <CForm
          ref="form"
          @submit.prevent="handleSubmit"
          :action="paths.actions.resetPassword"
          method="post"
          class="form-section">
          <div class="form-field">
            <label for="password" class="form-label">
              New Password
            </label>
            <div class="relative">
              <div class="form-icon-container">
                <CIcon icon="cil-lock-locked" class="form-icon" />
              </div>
              <CFormInput
                id="password"
                placeholder="Enter new password"
                type="password"
                :name="`${rootObjectName}[password]`"
                required
                v-model="password"
                class="form-input-with-icon" />
            </div>

            <!-- Password Strength Indicator -->
            <div v-if="password" class="mt-2">
              <div class="flex items-center space-x-2">
                <div class="flex-1 bg-gray-200 rounded-full h-2">
                  <div
                    class="h-2 rounded-full transition-all duration-300"
                    :class="passwordStrengthColorClass"
                    :style="{ width: `${passwordStrength}%` }"
                  >
                </div>
                </div>
                <span class="text-xs font-medium" :class="passwordStrengthTextClass">
                  {{ passwordStrengthText }}
                </span>
              </div>
              <p class="form-help-text mt-1">
                Use at least 8 characters with a mix of letters, numbers, and symbols.
              </p>
            </div>
          </div>

          <div class="form-field">
            <label for="passwordConfirmation" class="form-label">
              Confirm New Password
            </label>
            <div class="relative">
              <div class="form-icon-container">
                <CIcon icon="cil-lock-locked" class="form-icon" />
              </div>
              <CFormInput
                id="passwordConfirmation"
                placeholder="Confirm new password"
                type="password"
                :name="`${rootObjectName}[password_confirmation]`"
                required
                v-model="passwordConfirmation"
                class="form-input-with-icon" />
            </div>
            <div v-if="passwordConfirmation && password !== passwordConfirmation" class="form-error">
              Passwords do not match
            </div>
          </div>

          <CButton
            type="submit"
            :disabled="!isFormValid"
            class="btn-gradient-green btn-full-width">
            Update Password
          </CButton>
        </CForm>

        <!-- Success state info -->
        <div class="info-box-green">
          <div class="info-box-content">
            <svg class="info-box-icon-green" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            <div class="info-box-text">
              <p class="info-box-title-green">Security Tips</p>
              <ul class="info-box-text-green space-y-1">
                <li>• Use a unique password you haven't used elsewhere</li>
                <li>• Consider using a password manager</li>
                <li>• Don't share your password with anyone</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed, ref } from 'vue';
  import useAuth from '@/composables/useAuth';

  const { paths, rootObjectName } = useAuth();

  const form = ref<HTMLFormElement>();
  const password = ref('');
  const passwordConfirmation = ref('');

  const passwordStrength = computed(() => {
    let strength = 0;
    if (password.value.length >= 8)
      strength += 20;
    if (password.value.match(/[A-Z]/))
      strength += 20;
    if (password.value.match(/[a-z]/))
      strength += 20;
    if (password.value.match(/[0-9]/))
      strength += 20;
    if (password.value.match(/[^A-Za-z0-9]/))
      strength += 20;
    return strength;
  })

  const passwordStrengthInfo = computed(() => {
    if (passwordStrength.value <= 20)
      return { color: 'bg-red-500', textColor: 'text-red-600', text: 'Very Weak' };
    if (passwordStrength.value <= 40)
      return { color: 'bg-orange-500', textColor: 'text-orange-600', text: 'Weak' };
    if (passwordStrength.value <= 60)
      return { color: 'bg-yellow-500', textColor: 'text-yellow-600', text: 'Medium' };
    if (passwordStrength.value <= 80)
      return { color: 'bg-blue-500', textColor: 'text-blue-600', text: 'Strong' };
    return { color: 'bg-green-500', textColor: 'text-green-600', text: 'Very Strong' };
  })

  const passwordStrengthColorClass = computed(() => passwordStrengthInfo.value.color);
  const passwordStrengthTextClass = computed(() => passwordStrengthInfo.value.textColor);
  const passwordStrengthText = computed(() => passwordStrengthInfo.value.text);

  const isFormValid = computed(() => {
    return password.value.length >= 8 &&
      password.value === passwordConfirmation.value &&
      passwordStrength.value >= 40
  });

  function handleSubmit() {
    if (!isFormValid.value)
      return;
    form.value?.$el.submit();
  }
</script>

<style scoped>
</style>