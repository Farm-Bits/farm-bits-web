<template>
  <div class="page-container py-12 px-4">
    <CContainer class="auth-card-wide mx-auto">
      <div class="auth-card overflow-hidden">
        <!-- Form -->
        <div class="p-8">
          <FlashErrorMessages class="mb-6" />

          <CForm
            novalidate
            @submit.prevent="handleSubmit"
            class="form-section">
            <!-- Personal Information -->
            <div class="form-section">
              <h3 class="section-header-small">
                Personal Information
              </h3>

              <div class="form-field">
                <label for="name" class="form-label">
                  Name *
                </label>
                <CFormInput
                  id="name"
                  placeholder="Enter your name"
                  name="name"
                  v-model="formData.name"
                  :invalid="v$.name.$error"
                  @blur="v$.name.$touch()"
                  class="form-input" />
                <div class="form-error" v-if="v$.name.$error">
                  {{ v$.name.$errors[0].$message }}
                </div>
              </div>
            </div>

            <!-- Submit Button -->
            <div class="form-submit-section">
              <CButton type="submit" class="btn-gradient-green btn-full-width text-lg">
                Update My Profile
              </CButton>
            </div>
          </CForm>
        </div>
      </div>
    </CContainer>
  </div>
</template>

<script lang="ts" setup>
  import { useForm } from '@inertiajs/vue3';
  import { useVuelidate } from '@vuelidate/core';
  import { required } from '@vuelidate/validators';
  import useAuth from '@/composables/useAuth';

  const { user, paths } = useAuth();

  const formData = useForm({
    name: user.value?.name
  });

  function rules() {
    return {
      name: { required }
    };
  }

  const v$ = useVuelidate(rules, formData);

  async function handleSubmit() {
    const isValid = await v$.value.$validate();
    if (!isValid) {
      const firstInvalidElement = document.querySelector('.is-invalid');
      firstInvalidElement?.scrollIntoView({
        behavior: 'smooth',
        block: 'center'
      });
      return;
    }

    formData.put(paths.value.actions.clientSetup, {
      preserveState: true
    });
  }
</script>

<style scoped>
</style>
