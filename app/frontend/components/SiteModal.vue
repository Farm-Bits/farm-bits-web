<template>
  <CModal
    :visible="visible"
    @close="handleClose"
    backdrop="static">
    <CModalHeader>
      <CModalTitle>{{ isEditMode ? 'Update Site' : 'Create New Site' }}</CModalTitle>
    </CModalHeader>
    <CModalBody>
      <CAlert v-if="errors.submission" color="danger" class="d-flex align-items-center mb-3">
        <CIcon name="cilWarning" class="me-2" />
        <div>{{ errors.submission }}</div>
      </CAlert>

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

      <!-- Time Zone Selector -->
      <div class="mt-3">
        <label for="timeZone" class="form-label">
          Time Zone *
        </label>
        <CFormSelect
          id="timeZone"
          v-model="formData.site.time_zone"
          :invalid="v$.site.time_zone.$error"
          @blur="v$.site.time_zone.$touch()">
          <option value="">Select a time zone...</option>
          <optgroup
            v-for="region in timeZonesByRegion"
            :key="region.region"
            :label="region.region">
            <option
              v-for="timeZone in region.timeZones"
              :key="timeZone"
              :value="timeZone">
              {{ formatTimeZone(timeZone) }}
            </option>
          </optgroup>
        </CFormSelect>
        <div class="form-error" v-if="v$.site.time_zone.$error">
          {{ v$.site.time_zone.$errors[0].$message }}
        </div>
      </div>

      <!-- Segments Management (only in edit mode) -->
      <div v-if="isEditMode" class="mt-4">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <label class="form-label mb-0">Segments</label>
          <CButton
            color="primary"
            size="sm"
            variant="outline"
            @click="addSegment">
            <CIcon name="cilPlus" class="me-1" />
            Add Segment
          </CButton>
        </div>

        <div v-if="formData.site.segments_attributes.length === 0" class="text-muted small">
          No segments configured for this site
        </div>

        <CListGroup v-else>
          <CListGroupItem
            v-for="(segment, index) in formData.site.segments_attributes"
            :key="segment.id || `new-${index}`"
            class="d-flex justify-content-between align-items-center">
            <div class="flex-grow-1 me-2">
              <CFormInput
                v-model="segment.name"
                placeholder="Segment name"
                :invalid="!segment.name?.trim()"
                size="sm" />
            </div>
            <CButton
              color="danger"
              size="sm"
              variant="ghost"
              @click="removeSegment(index)">
              <CIcon name="cilTrash" />
            </CButton>
          </CListGroupItem>
        </CListGroup>
        <div class="form-text mt-2">
          Segments help organize different areas or zones within your farm site
        </div>
      </div>
    </CModalBody>
    <CModalFooter>
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
    </CModalFooter>
  </CModal>
</template>

<script lang="ts" setup>
  import { reactive, ref, computed, watch } from 'vue';
  import axios from 'axios';
  import { useVuelidate } from '@vuelidate/core';
  import { between, decimal, maxValue, minValue, required } from '@vuelidate/validators';
  import LocationSelector from '@/components/LocationSelector.vue';
  import { useApiCall } from '@/composables/useApi';
  import type { SiteWithSegments } from '@/types/inertia';
  import type { Segment, Site } from '@/types/location';
  import { ROUTES } from '@/types/permissions';

  type SegmentAttributes = Omit<Segment, 'id' | 'site_id'> & {
    id?: Segment['id'];
    _destroy?: boolean;
  };

  type SiteAttributes = Omit<Site, 'id'> & {
    id?: Site['id'];
    segments_attributes: SegmentAttributes[]
  };

  const props = defineProps<{
    visible: boolean;
    site?: SiteWithSegments | null;
  }>();

  const emit = defineEmits<{
    (e: 'close'): void;
    (e: 'success', site: SiteWithSegments): void;
  }>();

  const { execute } = useApiCall();

  const isLoading = ref(false);

  const formData = ref<{ site: SiteAttributes }>({
    site: {
      name: null,
      country: null,
      city: null,
      latitude: null,
      longitude: null,
      altitude: null,
      time_zone: 'UTC',
      segments_attributes: []
    }
  });

  const errors = reactive({
    submission: ''
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
      },
      time_zone: { required }
    }
  }));

  const v$ = useVuelidate(rules, formData);

  const isEditMode = computed(() => !!props.site?.id);

  const timeZonesByRegion = computed(() => {
    const regions: { [key: string]: string[] } = {};

    Intl.supportedValuesOf('timeZone').forEach((timeZone) => {
      const region = timeZone.split('/')[0];
      if (!regions[region])
        regions[region] = [];
      regions[region].push(timeZone);
    });

    return Object.entries(regions)
      .map(([region, timeZones]) => ({
        region,
        timeZones: timeZones.sort()
      }))
      .sort((a, b) => a.region.localeCompare(b.region));
  });

  function formatTimeZone(timeZone: string) {
    return timeZone.replace(/_/g, ' ');
  }

  function addSegment() {
    if (!props.site || !props.site.id)
      return;

    formData.value.site.segments_attributes.push({
      name: ''
    });
  }

  function removeSegment(index: number) {
    const segment = formData.value.site.segments_attributes[index];
    if (segment.id)
      segment._destroy = true;
    else
      formData.value.site.segments_attributes.splice(index, 1);
  }

  const hasSiteChanged = computed(() => {
    if (!isEditMode.value)
      return true;

    if (!props.site)
      return false;

    const siteChanged = Object.keys(formData.value.site).some((key) => {
      const formValue = formData.value.site[key as keyof typeof formData.value.site];
      const propValue = props.site![key as keyof Site];
      return formValue !== propValue;
    });

    const segmentsChanged = formData.value.site.segments_attributes.some((s) => !s.id || s._destroy);

    return siteChanged || segmentsChanged;
  });

  const areSegmentsValid = computed(() => {
    return formData.value.site.segments_attributes
      .filter((s) => !s._destroy)
      .every((s) => s.name?.trim());
  });

  const canSubmit = computed(() => {
    if (isEditMode.value)
      return hasSiteChanged.value && !v$.value.$invalid && areSegmentsValid.value;

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
          altitude: newSite.altitude,
          time_zone: newSite.time_zone,
          segments_attributes: newSite.segments ? newSite.segments.map(s => ({
            id: s.id,
            name: s.name
          })) : []
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
      altitude: null,
      time_zone: 'UTC',
      segments_attributes: []
    };

    errors.submission = '';

    isLoading.value = false;
    v$.value.$reset();
  }

  function handleClose() {
    resetForm();
    emit('close');
  }

  async function handleSubmit() {
    const isValid = await v$.value.$validate();
    if (!isValid || !areSegmentsValid.value)
      return;

    isLoading.value = true;

    const body = {
      site: formData.value.site,
      segments_attributes: formData.value.site.segments_attributes
        .filter((s) => !s._destroy || s.id)
        .map((s) => ({
          id: s.id,
          name: s.name,
          _destroy: s._destroy || false
        }))
    };
    const route = isEditMode.value ? ROUTES.sites_update : ROUTES.sites_create;
    const url = isEditMode.value
      ? route.path.replace(':id', String(props.site!.id))
      : route.path;

    const { success, data, error } = await execute<SiteWithSegments>(
      () => isEditMode.value ? axios.put(url, body) : axios.post(url, body),
      {
        showSuccessToast: true,
        successMessage: `Site ${isEditMode.value ? 'updated' : 'created'} successfully`
      }
    );

    if (success) {
      emit('success', data);
      resetForm();
    } else
      errors.submission = error.error || 'An error occurred';

    isLoading.value = false;
  }
</script>

<style scoped>
  .form-field {
    margin-bottom: 1rem;
  }

  .form-error {
    color: var(--cui-danger);
    font-size: 0.875rem;
    margin-top: 0.25rem;
  }
</style>
