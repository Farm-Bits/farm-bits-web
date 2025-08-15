import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

interface FormState {
  name?: string | null;
  email?: string | null;
  company?: string | null;
  country?: string | null;
  city?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  altitude?: number | null;
};

export default defineStore('auth', () => {
  const name = ref<string | null>(null);
  const email = ref<string | null>(null);
  const company = ref<string | null>(null);
  const country = ref<string | null>(null);
  const city = ref<string | null>(null);
  const latitude = ref<number | null>(null);
  const longitude = ref<number | null>(null);
  const altitude = ref<number | null>(null);
  const timeoutId = ref<number | null>(null);
  const expiresAt = ref<number | null>(null);

  function clearFormState() {
    name.value = null;
    email.value = null;
    company.value = null;
    country.value = null;
    city.value = null;
    latitude.value = null;
    longitude.value = null;
    altitude.value = null;
    expiresAt.value = null;

    if (timeoutId.value) {
      window.clearTimeout(timeoutId.value);
      timeoutId.value = null;
    }
  }

  function saveFormState(formData: FormState) {
    name.value = formData.name ?? null;
    email.value = formData.email ?? null;
    company.value = formData.company ?? null;
    country.value = formData.country ?? null;
    city.value = formData.city ?? null;
    latitude.value = formData.latitude ?? null;
    longitude.value = formData.longitude ?? null;
    altitude.value = formData.altitude ?? null;

    const timeoutMinutes = 10;
    expiresAt.value = Date.now() + (timeoutMinutes * 60 * 1000);
    timeoutId.value = window.setTimeout(() => {
      clearFormState();
    }, timeoutMinutes * 60 * 1000);
  }

  const formState = computed(() => {
    if (expiresAt.value && expiresAt.value < Date.now()) {
      clearFormState();
    }

    return {
      name: name.value,
      email: email.value,
      company: company.value,
      country: country.value,
      city: city.value,
      latitude: latitude.value,
      longitude: longitude.value,
      altitude: altitude.value
    };
  });

  return {
    name,
    email,
    company,
    country,
    city,
    latitude,
    longitude,
    altitude,
    timeoutId,
    expiresAt,
    formState,
    saveFormState,
    clearFormState
  };
}, {
  persist: true
});
