<template>
  <CModal
    :visible="visible"
    @close="handleClose"
    backdrop="static">
    <CModalHeader>
      <CModalTitle>{{ isEditMode ? 'Update Site' : 'Create New Site' }}</CModalTitle>
    </CModalHeader>
    <CModalBody>
      <div class="form-field">
        <label for="site" class="form-label">
          Site Name *
        </label>
        <CFormInput
          id="site"
          name="site"
          placeholder="Enter your site name"
          v-model="formData.site.name"
          :invalid="v$.site.name.$error"
          @blur="v$.site.name.$touch()"
          class="form-input" />
        <div class="form-error" v-if="v$.site.name.$error">
          {{ v$.site.name.$errors[0].$message }}
        </div>
      </div>

      <div class="mt-3">
        <LocationSelector
          v-model="formData.site"
          :errors="v$.site" />
      </div>
    </CModalBody>
    <CModalFooter>
      <div class="d-flex justify-content-between w-100">
        <div class="d-flex gap-2">
          <CButton
            color="secondary"
            @click="handleClose"
            :disabled="isLoading">
            Cancel
          </CButton>
          <CButton
            color="primary"
            :disabled="!canSubmit || isLoading"
            @click="handleSubmit">
            <CSpinner v-if="isLoading" size="sm" class="me-2" />
            {{ submitButtonText }}
          </CButton>
        </div>
      </div>
    </CModalFooter>
  </CModal>
</template>

<script lang="ts" setup>
  import { ref, computed, watch } from 'vue';
  import axios from 'axios';
  import { useVuelidate } from '@vuelidate/core';
  import { between, decimal, maxValue, minValue, required } from '@vuelidate/validators';
  import LocationSelector from '@/components/LocationSelector.vue';
  import { useApiCall } from '@/composables/useApi';
  import type { Site } from '@/types/location';
  import { ROUTES } from '@/types/permissions';

  const props = defineProps<{
    visible: boolean;
    site?: Site | null;
  }>();

  const emit = defineEmits<{
    (e: 'close'): void;
    (e: 'success', site: Site): void;
  }>();

  const { execute } = useApiCall();

  const isLoading = ref(false);

  const formData = ref<{ site: Omit<Site, 'id' | 'time_zone'> }>({
    site: {
      name: null,
      country: null,
      city: null,
      latitude: null,
      longitude: null,
      altitude: null
    }
  });

  const rules = computed(() => ({
    site: {
      name: { required },
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
  }));

  const v$ = useVuelidate(rules, formData);

  const isEditMode = computed(() => !!props.site?.id);

  const hasSiteChanged = computed(() => {
    if (!isEditMode.value)
      return true;

    if (!props.site)
      return false;

    return Object.keys(formData.value.site).some((key) => {
      const formValue = formData.value.site[key as keyof typeof formData.value.site];
      const propValue = props.site![key as keyof Site];
      return formValue !== propValue;
    });
  });

  const canSubmit = computed(() => {
    if (isEditMode.value)
      return hasSiteChanged.value && !v$.value.$invalid;

    return !v$.value.$invalid;
  });

  const submitButtonText = computed(() => {
    if (isLoading.value)
      return isEditMode.value ? 'Updating...' : 'Creating...';

    return isEditMode.value ? 'Update Site' : 'Create Site';
  });

  watch(
    () => props.site,
    (newSite) => {
      if (newSite) {
        formData.value.site = {
          name: newSite.name,
          country: newSite.country,
          city: newSite.city,
          latitude: newSite.latitude,
          longitude: newSite.longitude,
          altitude: newSite.altitude
        };
      } else
        resetForm();

      v$.value.$reset();
    },
    { immediate: true }
  );

  function resetForm() {
    formData.value.site = {
      name: null,
      country: null,
      city: null,
      latitude: null,
      longitude: null,
      altitude: null
    };
    isLoading.value = false;
    v$.value.$reset();
  }

  function handleClose() {
    resetForm();
    emit('close');
  }

  async function handleSubmit() {
    const isValid = await v$.value.$validate();
    if (!isValid)
      return;

    isLoading.value = true;

    const route = isEditMode.value ? ROUTES.sites_update : ROUTES.sites_create;
    const url = isEditMode.value
      ? route.path.replace(':id', String(props.site!.id))
      : route.path;

    const { success, data } = await execute<Site>(
      () => isEditMode.value ? axios.put(url, formData.value) : axios.post(url, formData.value),
      {
        showSuccessToast: true,
        successMessage: `Site ${isEditMode.value ? 'updated' : 'created'} successfully`,
        showErrorToast: true,
        errorTitle: 'Error'
      }
    );

    if (success) {
      emit('success', data);
      resetForm();
    }

    isLoading.value = false;
  }
</script>

<style scoped>
</style>
