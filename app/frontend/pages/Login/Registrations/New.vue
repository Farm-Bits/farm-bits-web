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
          <FlashMessages class="mb-6" />

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
                    placeholder="Enter your full name"
                    v-model="formData.user.name"
                    :invalid="v$.user.name.$error"
                    @blur="v$.user.name.$touch()"
                    class="form-input" />
                  <div class="form-error" v-if="v$.user.name.$error">
                    {{ v$.user.name.$errors[0].$message }}
                  </div>
                </div>

                <div class="form-field">
                  <label for="email" class="form-label">
                    Email Address *
                  </label>
                  <CFormInput
                    id="email"
                    placeholder="Enter your email"
                    type="email"
                    v-model="formData.user.email"
                    :invalid="v$.user.email.$error"
                    @blur="v$.user.email.$touch()"
                    class="form-input" />
                  <div class="form-error" v-if="v$.user.email.$error">
                    {{ v$.user.email.$errors[0].$message }}
                  </div>
                </div>
              </div>

              <div class="form-field">
                <label for="company" class="form-label">
                  Company Name *
                </label>
                <CFormInput
                  id="company"
                  placeholder="Enter your company name"
                  v-model="formData.user.client_attributes.name"
                  :invalid="v$.user.client_attributes.name.$error"
                  @blur="v$.user.client_attributes.name.$touch()"
                  class="form-input" />
                <div class="form-error" v-if="v$.user.client_attributes.name.$error">
                  {{ v$.user.client_attributes.name.$errors[0].$message }}
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
                    placeholder="Create a strong password"
                    type="password"
                    v-model="formData.user.password"
                    :invalid="v$.user.password.$error"
                    @blur="v$.user.password.$touch()"
                    class="form-input" />

                  <!-- Password Strength Indicator -->
                  <div v-if="formData.user.password" class="mt-2">
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

                  <div class="form-error" v-if="v$.user.password.$error">
                    {{ v$.user.password.$errors[0].$message }}
                  </div>
                </div>

                <div class="form-field">
                  <label for="passwordConfirmation" class="form-label">
                    Confirm Password *
                  </label>
                  <CFormInput
                    id="passwordConfirmation"
                    placeholder="Confirm your password"
                    type="password"
                    v-model="formData.user.password_confirmation"
                    :invalid="v$.user.password_confirmation.$error"
                    @blur="v$.user.password_confirmation.$touch()"
                    class="form-input" />
                  <div class="form-error" v-if="v$.user.password_confirmation.$error">
                    {{ v$.user.password_confirmation.$errors[0].$message }}
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
                v-model:country="formData.user.client_attributes.site_attributes.country"
                v-model:city="formData.user.client_attributes.site_attributes.city"
                v-model:latitude="formData.user.client_attributes.site_attributes.latitude"
                v-model:longitude="formData.user.client_attributes.site_attributes.longitude"
                v-model:altitude="formData.user.client_attributes.site_attributes.altitude" />

              <div class="form-field">
                <div class="form-error" v-if="v$.user.client_attributes.site_attributes.country.$error">
                  {{ v$.user.client_attributes.site_attributes.country.$errors[0].$message }}
                </div>
                <div class="form-error" v-if="v$.user.client_attributes.site_attributes.city.$error">
                  {{ v$.user.client_attributes.site_attributes.city.$errors[0].$message }}
                </div>
                <div class="form-error" v-if="v$.user.client_attributes.site_attributes.latitude.$error">
                  {{ v$.user.client_attributes.site_attributes.latitude.$errors[0].$message }}
                </div>
                <div class="form-error" v-if="v$.user.client_attributes.site_attributes.longitude.$error">
                  {{ v$.user.client_attributes.site_attributes.longitude.$errors[0].$message }}
                </div>
                <div class="form-error" v-if="v$.user.client_attributes.site_attributes.altitude.$error">
                  {{ v$.user.client_attributes.site_attributes.altitude.$errors[0].$message }}
                </div>
              </div>
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
  import { required, email, minLength, sameAs, numeric, decimal, between, minValue, maxValue } from '@vuelidate/validators';
  import LocationSelector from '@/components/LocationSelector.vue';
  import useAuth from '@/composables/useAuth';

  const { paths, features } = useAuth();

  const formData = useForm({
    user: {
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
    if (formData.user.password.length >= 8)
      strength += 20;
    if (formData.user.password.match(/[A-Z]/))
      strength += 20;
    if (formData.user.password.match(/[a-z]/))
      strength += 20;
    if (formData.user.password.match(/[0-9]/))
      strength += 20;
    if (formData.user.password.match(/[^A-Za-z0-9]/))
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

  const v$ = useVuelidate(rules, formData);

  function rules() {
    return {
      user: {
        name: { required },
        email: { required, email },
        password: { required, minLength: minLength(8) },
        password_confirmation: { required, sameAs: sameAs(formData.user.password) },
        client_attributes: {
          name: { required }, // This is your company field
          site_attributes: {
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
          }
        }
      }
    };
  }

  async function handleSubmit() {
    if (!features.value.canRegister)
      return;

    const isValid = await v$.value.$validate();
    if (!isValid)
      return;

    formData.post(paths.value.actions.signUp, {
      preserveScroll: true,
      preserveState: true
    });
  }
</script>

<style scoped>
</style>
