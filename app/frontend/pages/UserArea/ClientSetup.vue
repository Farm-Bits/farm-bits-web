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
            <!-- Company Information -->
            <div class="form-section">
              <h3 class="section-header-small">
                Company Information
              </h3>

              <div class="form-field">
                <label for="company" class="form-label">
                  Company Name *
                </label>
                <CFormInput
                  id="company"
                  name="company"
                  placeholder="Enter your company name"
                  v-model="formData.client.name"
                  :invalid="v$.client.name.$error"
                  @blur="v$.client.name.$touch()"
                  class="form-input" />
                <div class="form-error" v-if="v$.client.name.$error">
                  {{ v$.client.name.$errors[0].$message }}
                </div>
              </div>
            </div>

            <!-- Location Section -->
            <div class="form-section">
              <h3 class="section-header-small">
                Site Location
              </h3>

              <LocationSelector
                v-model="formData.client.site_attributes"
                :errors="v$.client.site_attributes" />
            </div>

            <!-- Submit Button -->
            <div class="form-submit-section">
              <CButton type="submit" class="btn-gradient-green btn-full-width text-lg">
                Create Company
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
  import { between, decimal, maxValue, minValue, required } from '@vuelidate/validators';
  import LocationSelector from '@/components/LocationSelector.vue';
  import useAuth from '@/composables/useAuth';

  const { paths } = useAuth();

  const formData = useForm({
    client: {
      name: null,
      site_attributes: {
        country: null,
        city: null,
        latitude: null,
        longitude: null,
        altitude: null
      }
    }
  });

  function rules() {
    return {
      client: {
        name: { required },
        site_attributes: {
          country: { required },
          city: {},
          latitude: {
            decimal,
            between: between(-90, 90)
          },
          longitude: {
            decimal,
            between: between(-180, 180)
          },
          altitude: {
            decimal,
            minValue: minValue(-431),
            maxValue: maxValue(8849)
          }
        }
      }
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

    formData.post(paths.value.actions.clientSetup, {
      preserveState: true
    });
  }
</script>

<style scoped>
</style>
