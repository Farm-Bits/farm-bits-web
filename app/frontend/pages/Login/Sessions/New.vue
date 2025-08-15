<template>
  <div class="auth-container">
    <div class="w-full max-w-6xl grid lg:grid-cols-2 gap-8 items-center">
      <!-- Left side - Branding -->
      <div class="hidden lg:block">
        <div class="text-center space-y-6">
          <h1 class="text-4xl font-bold gradient-text-primary">
            Welcome to Farm Bits
          </h1>
          <p class="text-xl text-gray-600 leading-relaxed">
            Transform your agricultural operations with smart technology solutions that drive efficiency and growth.
          </p>
        </div>
      </div>

      <!-- Right side - Login Form -->
      <div class="auth-card-narrow mx-auto">
        <div class="auth-card">
          <div class="auth-header">
            <h2 class="auth-title">Welcome Back</h2>
            <p class="auth-subtitle">Sign in to your account</p>
          </div>

          <FlashMessages class="mb-6" />

          <CForm
            ref="form"
            @submit.prevent="handleSubmit"
            :action="paths.actions.signIn"
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
                  placeholder="Enter your email"
                  autocomplete="email"
                  type="email"
                  :name="`${rootObjectName}[email]`"
                  required
                  v-model="email"
                  class="form-input-with-icon" />
              </div>
            </div>

            <div class="form-field">
              <label for="password" class="form-label">
                Password
              </label>
              <div class="relative">
                <div class="form-icon-container">
                  <CIcon icon="cil-lock-locked" class="form-icon" />
                </div>
                <CFormInput
                  id="password"
                  placeholder="Enter your password"
                  type="password"
                  :name="`${rootObjectName}[password]`"
                  required
                  class="form-input-with-icon" />
              </div>
            </div>

            <div class="flex items-center justify-between">
              <CFormCheck
                label="Remember me"
                :name="`${rootObjectName}[remember_me]`"
                class="text-sm text-gray-600" />
              <a v-if="features.canRecover" :href="paths.pages.forgotPassword" class="nav-link-primary">
                Forgot password?
              </a>
            </div>

            <CButton type="submit" class="btn-gradient-green btn-full-width">
              Sign In
            </CButton>
          </CForm>

          <!-- Registration prompt -->
          <div v-if="features.canRegister" class="form-divider">
            <p class="text-gray-600">
              Don't have an account?
              <a :href="paths.pages.signUp" class="nav-link-primary">
                Sign Up
              </a>
            </p>
          </div>

          <!-- Additional links -->
          <div class="nav-divider">
            <div v-if="features.canConfirm">
              <a :href="paths.pages.confirmation" class="nav-link-primary">
                Didn't receive confirmation instructions?
              </a>
            </div>
            <div v-if="features.canUnlock">
              <a :href="paths.pages.unlock" class="nav-link-primary">
                Account locked?
              </a>
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
  import useAuthStore from '@/stores/auth';

  const { paths, rootObjectName, features } = useAuth();

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
