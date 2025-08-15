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
          <h2 class="auth-title">Forgot Password?</h2>
          <p class="auth-subtitle">No worries! Enter your email and we'll send you reset instructions.</p>
        </div>

        <FlashMessages class="mb-6" />

        <CForm
          :action="paths.actions.resetPassword"
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
                class="form-input-with-icon" />
            </div>
          </div>

          <CButton type="submit" class="btn-gradient-green btn-full-width">
            Send Reset Instructions
          </CButton>
        </CForm>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import useAuth from '@/composables/useAuth';

  const { paths, rootObjectName } = useAuth();
</script>

<style scoped>
</style>
