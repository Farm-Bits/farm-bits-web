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

        <FlashErrorMessages class="mb-6" />

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
                class="form-input-with-icon"
                v-model="formData[rootObjectName].email" />
              <div class="form-error" v-if="v$[rootObjectName].email.$error">
                {{ v$[rootObjectName].email.$errors[0].$message }}
              </div>
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
  import { useForm } from '@inertiajs/vue3';
  import { useVuelidate } from '@vuelidate/core';
  import { email, required } from '@vuelidate/validators';
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
    if (!features.value.canRecover)
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

    formData.post(paths.value.actions.resetPassword, {
      preserveState: true
    });
  }
</script>

<style scoped>
</style>
