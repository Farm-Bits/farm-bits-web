<template>
  <div class="auth-container">
    <div class="auth-card-narrow">
      <div class="auth-card">
        <!-- Header -->
        <div class="auth-header">
          <div class="w-16 h-16 rounded-2xl flex items-center justify-center mx-auto mb-4" style="background: linear-gradient(135deg, var(--feature-purple-color) 0%, #f59e0b 100%);">
            <svg class="auth-icon-svg" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
            </svg>
          </div>
          <h2 class="auth-title">Account Locked</h2>
          <p class="auth-subtitle">We'll send you instructions to unlock your account.</p>
        </div>

        <FlashMessages class="mb-6" />

        <CForm
          ref="form"
          @submit.prevent="handleSubmit"
          :action="paths.actions.unlock"
          method="post"
          class="form-section">
          <div class="form-field">
            <label for="email" class="form-label">
              Email Address
            </label>
            <div class="relative">
              <div class="form-icon-container">
                <CIcon icon="cil-user" class="form-icon" />
              </div>
              <CFormInput
                id="email"
                placeholder="Enter your email address"
                autocomplete="email"
                type="email"
                :name="`${rootObjectName}[email]`"
                required
                v-model="email"
                class="pl-10 block w-full rounded-xl border-gray-300 shadow-sm py-3"
                style="border-color: var(--feature-purple-color) !important; --tw-ring-color: var(--feature-purple-color) !important;" />
            </div>
            <p class="form-help-text">
              Enter the email address associated with your locked account.
            </p>
          </div>

          <CButton type="submit" class="btn-gradient-green btn-full-width">
            Send Unlock Instructions
          </CButton>
        </CForm>

        <!-- Info section -->
        <div class="mt-6 p-4 rounded-xl" style="background-color: rgba(var(--feature-purple-color-rgb), 0.1);">
          <div class="info-box-content">
            <svg class="w-5 h-5 mt-0.5 mr-3 flex-shrink-0" style="color: var(--feature-purple-color);" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"></path>
            </svg>
            <div class="info-box-text">
              <p class="font-medium mb-1" style="color: var(--feature-purple-color);">Why was my account locked?</p>
              <p style="color: var(--feature-purple-color);">
                Accounts are automatically locked after multiple failed login attempts to protect your security.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import useAuth from '@/composables/useAuth';
  import useAuthStore from '@/stores/auth'

  const { paths, rootObjectName } = useAuth();

  const { formState, saveFormState } = useAuthStore();

  const form = ref<HTMLFormElement>();
  const email = ref(formState.email);

  function handleSubmit() {
    saveFormState({ email: email.value });
    form.value?.$el.submit();
  }
</script>

<style scoped>
</style>
