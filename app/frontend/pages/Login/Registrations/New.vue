<template>
  <div class="page-container py-12 px-4">
    <CContainer class="auth-card-wide mx-auto">
      <div class="auth-card overflow-hidden">
        <!-- Header -->
        <div class="registration-header">
          <h1 class="registration-title">Join Farm Bits</h1>
          <p class="registration-subtitle">Start transforming your agriculture today</p>
        </div>

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

              <div class="form-grid">
                <div class="form-field">
                  <label for="name" class="form-label">
                    Full Name *
                  </label>
                  <CFormInput
                    id="name"
                    name="name"
                    placeholder="Enter your full name"
                    v-model="formData[rootObjectName].name"
                    :invalid="v$[rootObjectName].name.$error"
                    @blur="v$[rootObjectName].name.$touch()"
                    class="form-input" />
                  <div class="form-error" v-if="v$[rootObjectName].name.$error">
                    {{ v$[rootObjectName].name.$errors[0].$message }}
                  </div>
                </div>

                <div class="form-field">
                  <label for="email" class="form-label">
                    Email Address *
                  </label>
                  <CFormInput
                    id="email"
                    name="email"
                    placeholder="Enter your email"
                    type="email"
                    v-model="formData[rootObjectName].email"
                    :invalid="v$[rootObjectName].email.$error"
                    @blur="v$[rootObjectName].email.$touch()"
                    class="form-input" />
                  <div class="form-error" v-if="v$[rootObjectName].email.$error">
                    {{ v$[rootObjectName].email.$errors[0].$message }}
                  </div>
                </div>
              </div>

              <div class="form-field">
                <label for="company" class="form-label">
                  Company Name *
                </label>
                <CFormInput
                  id="company"
                  name="company"
                  placeholder="Enter your company name"
                  v-model="formData[rootObjectName].client_attributes.name"
                  :invalid="v$[rootObjectName].client_attributes.name.$error"
                  @blur="v$[rootObjectName].client_attributes.name.$touch()"
                  class="form-input" />
                <div class="form-error" v-if="v$[rootObjectName].client_attributes.name.$error">
                  {{ v$[rootObjectName].client_attributes.name.$errors[0].$message }}
                </div>
              </div>
            </div>

            <!-- Password Section -->
            <div class="form-section">
              <h3 class="section-header-small">
                Security
              </h3>

              <div class="form-grid">
                <div class="form-field">
                  <label for="password" class="form-label">
                    Password *
                  </label>
                  <CFormInput
                    id="password"
                    name="password"
                    placeholder="Create a strong password"
                    type="password"
                    v-model="formData[rootObjectName].password"
                    :invalid="v$[rootObjectName].password.$error"
                    @blur="v$[rootObjectName].password.$touch()"
                    class="form-input" />

                  <!-- Password Strength Indicator -->
                  <div v-if="formData[rootObjectName].password" class="mt-2">
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
                  </div>

                  <div class="form-error" v-if="v$[rootObjectName].password.$error">
                    {{ v$[rootObjectName].password.$errors[0].$message }}
                  </div>
                </div>

                <div class="form-field">
                  <label for="passwordConfirmation" class="form-label">
                    Confirm Password *
                  </label>
                  <CFormInput
                    id="passwordConfirmation"
                    name="passwordConfirmation"
                    placeholder="Confirm your password"
                    type="password"
                    v-model="formData[rootObjectName].password_confirmation"
                    :invalid="v$[rootObjectName].password_confirmation.$error"
                    @blur="v$[rootObjectName].password_confirmation.$touch()"
                    class="form-input" />
                  <div class="form-error" v-if="v$[rootObjectName].password_confirmation.$error">
                    {{ v$[rootObjectName].password_confirmation.$errors[0].$message }}
                  </div>
                </div>
              </div>
            </div>

            <!-- Location Section -->
            <div class="form-section">
              <h3 class="section-header-small">
                Site Location
              </h3>

              <LocationSelector
                v-model="formData[rootObjectName].client_attributes.site_attributes"
                :errors="v$[rootObjectName].client_attributes.site_attributes" />
            </div>

            <!-- Submit Button -->
            <div class="form-submit-section">
              <CButton type="submit" class="btn-gradient-green btn-full-width text-lg">
                Create Account
              </CButton>
            </div>

            <!-- Login link -->
            <div class="form-divider">
              <p class="text-gray-600">
                Already have an account?
                <a :href="paths.pages.signIn" class="nav-link-primary">
                  Sign in here
                </a>
              </p>
            </div>
          </CForm>
        </div>
      </div>
    </CContainer>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import { useForm } from '@inertiajs/vue3';
  import { useVuelidate } from '@vuelidate/core';
  import { between, decimal, email, maxValue, minLength, minValue, required, sameAs } from '@vuelidate/validators';
  import LocationSelector from '@/components/LocationSelector.vue';
  import useAuth from '@/composables/useAuth';

  const { paths, rootObjectName, features } = useAuth();

  const formData = useForm({
    [rootObjectName.value]: {
      name: null,
      email: null,
      password: '',
      password_confirmation: '',
      client_attributes: {
        name: null,
        site_attributes: {
          country: null,
          city: null,
          latitude: null,
          longitude: null,
          altitude: null
        }
      }
    }
  });

  const passwordStrength = computed(() => {
    let strength = 0;
    if (formData[rootObjectName.value].password.length >= 8)
      strength += 20;
    if (formData[rootObjectName.value].password.match(/[A-Z]/))
      strength += 20;
    if (formData[rootObjectName.value].password.match(/[a-z]/))
      strength += 20;
    if (formData[rootObjectName.value].password.match(/[0-9]/))
      strength += 20;
    if (formData[rootObjectName.value].password.match(/[^A-Za-z0-9]/))
      strength += 20;
    return strength;
  });

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
  });

  const passwordStrengthColorClass = computed(() => passwordStrengthInfo.value.color);
  const passwordStrengthTextClass = computed(() => passwordStrengthInfo.value.textColor);
  const passwordStrengthText = computed(() => passwordStrengthInfo.value.text);

  function rules() {
    return {
      [rootObjectName.value]: {
        name: { required },
        email: { required, email },
        password: { required, minLength: minLength(8) },
        password_confirmation: { required, sameAs: sameAs(formData[rootObjectName.value].password) },
        client_attributes: {
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
      }
    };
  }

  const v$ = useVuelidate(rules, formData);

  async function handleSubmit() {
    if (!features.value.canRegister)
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

    formData.post(paths.value.actions.signUp, {
      preserveState: true
    });
  }
</script>

<style scoped>
</style>
