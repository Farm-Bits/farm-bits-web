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
            <input type="hidden" name="_method" value="put">

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
                  v-model="formData.name"
                  :invalid="v$.name.$error"
                  @blur="v$.name.$touch()"
                  class="form-input" />
                <div class="form-error" v-if="v$.name.$error">
                  {{ v$.name.$errors[0].$message }}
                </div>
              </div>

              <div class="form-field">
                <label class="form-label">
                  Company Color
                </label>
                <input name="client[color]" :value="formData.color" type="hidden" />
                <ColorPicker
                  v-model="formData.color"
                  :invalid="v$.color.$error"
                  @blur="v$.color.$touch()" />
                <div class="form-error" v-if="v$.color.$error">
                  {{ v$.color.$errors[0].$message }}
                </div>
              </div>
            </div>

            <!-- Submit Button -->
            <div class="form-submit-section">
              <CButton type="submit" class="btn-gradient-green btn-full-width text-lg">
                Update Company
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
  import { required } from '@vuelidate/validators';
  import ColorPicker from '@/components/ColorPicker.vue';
  import useAuth from '@/composables/useAuth';

  const { client, paths } = useAuth();

  const form = ref<HTMLFormElement>();
  const formData = reactive({
    name: client.value?.name,
    color: client.value?.color || null
  });

  const isValidHexColor = (value: string | null) => {
    if (!value)
      return true;
    return /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(value);
  };

  const v$ = useVuelidate(rules, formData);

  function rules() {
    return {
      name: { required },
      color: {
        isValidHexColor: {
          $validator: isValidHexColor,
          $message: 'Please enter a valid hex color (e.g., #FF0000)'
        }
      }
    };
  }

  async function handleSubmit() {
    const isValid = await v$.value.$validate();
    if (!isValid)
      return;

    form.value?.$el.submit();
  }
</script>

<style scoped>
</style>
