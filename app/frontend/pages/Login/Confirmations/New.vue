<template>
  <div class="auth-container">
    <div class="auth-card-narrow">
      <div class="auth-card">
        <!-- Header -->
        <div class="auth-header">
          <div class="auth-icon-blue">
            <svg class="auth-icon-svg" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 7.89a2 2 0 002.83 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
            </svg>
          </div>
          <h2 class="auth-title">Resend Confirmation</h2>
          <p class="auth-subtitle">We'll send you a new confirmation email to activate your account.</p>
        </div>

        <FlashMessages class="mb-6" />

        <CForm
          novalidate
          @submit.prevent="handleSubmit"
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
                name="email"
                placeholder="Enter your email address"
                autocomplete="email"
                type="email"
                required
                v-model="formData[rootObjectName].email"
                class="form-input-with-icon-secondary" />
            </div>
            <div class="form-error" v-if="v$[rootObjectName].email.$error">
              {{ v$[rootObjectName].email.$errors[0].$message }}
            </div>
            <p class="form-help-text">
              Enter the email address you used to register your account.
            </p>
          </div>

          <CButton type="submit" class="btn-gradient-green btn-full-width">
            Resend Confirmation Email
          </CButton>
        </CForm>

        <!-- Help text -->
        <div class="info-box-blue">
          <div class="info-box-content">
            <svg class="info-box-icon-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            <div class="info-box-text">
              <p class="info-box-title-blue">Need help?</p>
              <p class="info-box-text-blue">
                Check your spam folder if you don't receive the email within a few minutes.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { useForm } from '@inertiajs/vue3';
  import { useVuelidate } from '@vuelidate/core';
  import { required, email } from '@vuelidate/validators';
  import useAuth from '@/composables/useAuth';

  const { paths, rootObjectName, features } = useAuth();

  const formData = useForm({
    [rootObjectName.value]: {
      email: null
    }
  });

  function rules() {
    return {
      [rootObjectName.value]: {
        email: { required, email }
      }
    };
  }

  const v$ = useVuelidate(rules, formData);

  async function handleSubmit() {
    if (!features.value.canConfirm)
      return;

    const isValid = await v$.value.$validate();
    if (!isValid) {
      const firstInvalidElement = document.querySelector('.is-invalid');
      firstInvalidElement?.scrollIntoView({
        behavior: 'smooth',
        block: 'center'
      });
      return;
    }

    formData.post(paths.value.actions.confirmation, {
      preserveState: true
    });
  }
</script>

<style scoped>
</style>
