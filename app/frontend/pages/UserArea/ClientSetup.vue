<template>
  <div class="page-container py-12 px-4">
    <CContainer class="auth-card-wide mx-auto">
      <div class="auth-card overflow-hidden">
        <!-- Form -->
        <div class="p-8">
          <FlashMessages class="mb-6" />

          <CForm
            ref="form"
            @submit.prevent="handleSubmit"
            novalidate
            :action="paths.actions.clientSetup"
            method="post"
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
                  placeholder="Enter your company name"
                  name="client[name]"
                  v-model="formData.company"
                  :invalid="v$.company.$error"
                  @blur="v$.company.$touch()"
                  class="form-input" />
                <div class="form-error" v-if="v$.company.$error">
                  {{ v$.company.$errors[0].$message }}
                </div>
              </div>
            </div>

            <!-- Location Section -->
            <div class="form-section">
              <h3 class="section-header-small">
                Site Location
              </h3>

              <LocationSelector
                nameAttribute="client[site_attributes]"
                v-model:country="formData.country"
                v-model:city="formData.city"
                v-model:latitude="formData.latitude"
                v-model:longitude="formData.longitude"
                v-model:altitude="formData.altitude" />

              <div class="form-field">
                <div class="form-error" v-if="v$.country.$error">
                  {{ v$.country.$errors[0].$message }}
                </div>
                <div class="form-error" v-if="v$.city.$error">
                  {{ v$.city.$errors[0].$message }}
                </div>
                <div class="form-error" v-if="v$.latitude.$error">
                  {{ v$.latitude.$errors[0].$message }}
                </div>
                <div class="form-error" v-if="v$.longitude.$error">
                  {{ v$.longitude.$errors[0].$message }}
                </div>
                <div class="form-error" v-if="v$.altitude.$error">
                  {{ v$.altitude.$errors[0].$message }}
                </div>
              </div>
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
  import { reactive, ref } from 'vue';
  import { useVuelidate } from '@vuelidate/core';
  import { required, numeric, decimal, between, minValue, maxValue } from '@vuelidate/validators';
  import LocationSelector from '@/components/LocationSelector.vue';
  import useAuth from '@/composables/useAuth';
  import useAuthStore from '@/stores/auth';

  const { paths } = useAuth();

  const { formState, saveFormState } = useAuthStore();

  const form = ref<HTMLFormElement>();
  const formData = reactive({ ...formState });

  const v$ = useVuelidate(rules, formData);

  function rules() {
    return {
      company: { required },
      country: { required },
      city: {},
      latitude: {
        numeric,
        decimal,
        between: between(-90, 90)
      },
      longitude: {
        numeric,
        decimal,
        between: between(-180, 180)
      },
      altitude: {
        numeric,
        decimal,
        minValue: minValue(-431),
        maxValue: maxValue(8849)
      }
    };
  }

  async function handleSubmit() {
    saveFormState(formData);
    const isValid = await v$.value.$validate();
    if (!isValid)
      return;

    form.value?.$el.submit();
  }
</script>

<style scoped>
</style>
