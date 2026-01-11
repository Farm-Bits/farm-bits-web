<template>
  <div class="form-section">
    <!-- Current Location Button -->
    <div class="flex justify-start">
      <CButton
        color="secondary"
        :disabled="loadingPosition"
        @click="getCurrentPosition">
        <CSpinner v-if="loadingPosition" size="sm" class="me-2" />
        <CIcon name="cilLocationPin" class="me-2" />
        Use Current Location
      </CButton>
    </div>

    <!-- Location Selection Grid -->
    <div class="form-grid">
      <!-- Country Selection -->
      <div class="form-field">
        <label for="country" class="form-label">
          Country *
        </label>
        <div class="relative">
          <VueSelect
            id="country"
            name="country"
            placeholder="Type to search..."
            v-model="countryModel"
            :options="countries"
            :isLoading="loadingCountries"
            :isDisabled="!autocompleteService"
            @search="searchCountries" />
          <div class="form-error" v-if="errors.country.$error">
            {{ errors.country.$errors[0].$message }}
          </div>
        </div>
      </div>

      <!-- City Selection -->
      <div class="form-field">
        <label for="city" class="form-label">
          City
        </label>
        <div class="relative">
          <VueSelect
            id="city"
            name="city"
            v-model="cityModel"
            :placeholder="!countryModel ? 'Select country first' : 'Type to search city...'"
            :options="cities"
            :isLoading="loadingCities"
            :isDisabled="!autocompleteService || !countryModel"
            @search="searchCities" />
          <div class="form-error" v-if="errors.city.$error">
            {{ errors.city.$errors[0].$message }}
          </div>
        </div>
      </div>
    </div>

    <!-- Coordinates and Map Section -->
    <div v-show="displayMap">
      <!-- <div class="form-grid-3">
        Coordinate Inputs
        <div class="form-field">
          <label for="latitude" class="form-label">
            Latitude
          </label>
          <div class="relative">
            <CFormInput
              id="latitude"
              name="latitude"
              placeholder="e.g., 40.7128"
              inputmode="numeric"
              class="form-input"
              v-model="latitudeModel"
              @change="manualCoordinateChanges" />
            <div class="form-error" v-if="errors.latitude.$error">
              {{ errors.latitude.$errors[0].$message }}
            </div>
          </div>
        </div>

        <div class="form-field">
          <label for="longitude" class="form-label">
            Longitude
          </label>
          <div class="relative">
            <CFormInput
              id="longitude"
              name="longitude"
              placeholder="e.g., -74.0060"
              inputmode="numeric"
              class="form-input"
              v-model="longitudeModel"
              @change="manualCoordinateChanges"/>
            <div class="form-error" v-if="errors.longitude.$error">
              {{ errors.longitude.$errors[0].$message }}
            </div>
          </div>
        </div>

        <div class="form-field">
          <label for="altitude" class="form-label">
            Altitude (meters)
          </label>
          <div class="relative">
            <CFormInput
              id="altitude"
              name="altitude"
              placeholder="e.g., 150"
              inputmode="numeric"
              class="form-input"
              v-model="altitudeModel" />
            <div class="form-error" v-if="errors.altitude.$error">
              {{ errors.altitude.$errors[0].$message }}
            </div>
          </div>
        </div>
      </div> -->

      <!-- Coordinate Info -->
      <div class="info-box-blue">
        <div class="info-box-content">
          <svg class="info-box-icon-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <div class="info-box-text">
            <p class="info-box-title-blue">Tip</p>
            <p class="info-box-text-blue">
              Drag the map marker or enter coordinates manually for precise positioning.
            </p>
          </div>
        </div>
      </div>

      <!-- Interactive Map -->
      <div class="lg:col-span-2 space-y-4">
        <div class="flex items-center justify-between">
          <h4 class="text-md font-medium text-gray-700">Interactive Map</h4>
          <div class="flex items-center text-sm text-gray-500">
            <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 11.5V14m0-2.5v-6a1.5 1.5 0 113 0m-3 6a1.5 1.5 0 00-3 0v2a7.5 7.5 0 0015 0v-5a1.5 1.5 0 00-3 0m-6-3V11m0-5.5v-1a1.5 1.5 0 013 0v1m0 0V11m0-5.5T16.5 4.5m-1.5 0H16"></path>
            </svg>
            Drag marker to set location
          </div>
        </div>

        <div class="relative">
          <div
            ref="mapContainer"
            class="map-container"
            style="min-height: 320px;">
          </div>

          <!-- Map Loading Overlay -->
          <div v-if="!map" class="absolute inset-0 flex items-center justify-center bg-gray-100 rounded-xl">
            <div class="text-center">
              <div class="loading-spinner mx-auto mb-2"></div>
              <p class="text-gray-600 text-sm">Loading map...</p>
            </div>
          </div>
        </div>
        <a @click="clearCoordinates" class="nav-link-secondary cursor-pointer">
          Clear Coordinates
        </a>
      </div>

      <div class="form-error" v-if="errors.latitude.$error">
        {{ errors.latitude.$errors[0].$message }}
      </div>
      <div class="form-error" v-if="errors.longitude.$error">
        {{ errors.longitude.$errors[0].$message }}
      </div>
      <div class="form-error" v-if="errors.altitude.$error">
        {{ errors.altitude.$errors[0].$message }}
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed, nextTick, onMounted, ref } from 'vue';
  import { Loader } from '@googlemaps/js-api-loader';
  import { type Validation, type ValidationArgs } from '@vuelidate/core'
  import useToastStore from '@/stores/toast';

  type Location = {
    country: string | null;
    city: string | null;
    latitude: string | number | null;
    longitude: string | number | null;
    altitude: string | number | null;
  };
  const props = defineProps<{
    modelValue: Location;
    errors: Validation<ValidationArgs<Location>, Location>;
  }>();

  const API_KEY = '***REMOVED***';

  const mapContainer = ref<HTMLElement | null>(null);
  const map = ref<google.maps.Map | null>(null);
  const marker = ref<google.maps.marker.AdvancedMarkerElement | null>(null);
  const autocompleteService = ref<boolean>(false);
  const countries = ref<{ value: string; label: string }[]>([]);
  const cities = ref<{ value: string; label: string }[]>([]);
  const loadingPosition = ref(false);
  const loadingCountries = ref(false);
  const loadingCities = ref(false);
  const displayMap = ref(false);

  const loader = new Loader({
    apiKey: API_KEY,
    version: 'weekly'
  });

  const { addToast } = useToastStore();

  const emit = defineEmits<{
    'update:modelValue': [value: Location];
  }>();

  const countryModel = computed({
    get: () => props.modelValue.country,
    set: (value: string | null) => {
      emit('update:modelValue', { ...props.modelValue, country: value, city: null });
      cities.value = [];
    }
  });

  const cityModel = computed({
    get: () => props.modelValue.city,
    set: (value: string | null) => emit('update:modelValue', { ...props.modelValue, city: value })
  });

  const latitudeModel = computed({
    get: () => props.modelValue.latitude,
    set: (value: string | number | null) => {
      let newValue: string | number | null = null;

      if (value !== null)
        newValue = typeof value === 'string' && value !== '' ? parseFloat(value) : value;

      emit('update:modelValue', { ...props.modelValue, latitude: newValue });
    }
  });

  const longitudeModel = computed({
    get: () => props.modelValue.longitude,
    set: (value: string | number | null) => {
      let newValue: string | number | null = null;

      if (value !== null)
        newValue = typeof value === 'string' && value !== '' ? parseFloat(value) : value;

      emit('update:modelValue', { ...props.modelValue, longitude: newValue });
    }
  });

  const altitudeModel = computed({
    get: () => props.modelValue.altitude,
    set: (value: string | number | null) => {
      let newValue: string | number | null = null;

      if (value !== null)
        newValue = typeof value === 'string' && value !== '' ? parseFloat(value) : value;

      emit('update:modelValue', { ...props.modelValue, altitude: newValue });
    }
  });

  async function getElevation(position: google.maps.LatLng | google.maps.LatLngLiteral | google.maps.LatLngAltitudeLiteral) {
    const elevationService = new google.maps.ElevationService();
    const elevation = await elevationService.getElevationForLocations({
      locations: [position]
    });
    return elevation.results[0]?.elevation;
  }

  function isValidCoordinate(value: string | number | null): value is number {
    return value != null && typeof value === 'number' && !isNaN(value);
  }

  function updateCoordinates(latitude: number | null, longitude: number | null, altitude: number | null) {
    emit('update:modelValue', {
      ...props.modelValue,
      latitude,
      longitude,
      altitude
    });
  }

  async function initMap() {
    try {
      const { Map } = await loader.importLibrary('maps');
      const { AdvancedMarkerElement } = await loader.importLibrary('marker');

      if (!mapContainer.value)
        return;

      let mapCenter = new google.maps.LatLng(0, 0);
      let mapZoom = 2;
      let markerPosition: google.maps.LatLng | null = null;

      if (isValidCoordinate(latitudeModel.value) && isValidCoordinate(longitudeModel.value)) {
        const position = new google.maps.LatLng(latitudeModel.value, longitudeModel.value);
        mapCenter = position;
        mapZoom = 12;
        markerPosition = position;
      }

      const mapInstance = new Map(mapContainer.value, {
        mapId: API_KEY,
        center: mapCenter,
        zoom: mapZoom,
        streetViewControl: false,
        mapTypeControl: true,
        fullscreenControl: true,
        zoomControl: true
      });
      map.value = mapInstance;

      const markerInstance = new AdvancedMarkerElement({
        map: mapInstance,
        position: markerPosition,
        gmpDraggable: true
      });

      markerInstance.addListener('dragend', async () => {
        const newPosition = markerInstance.position;
        if (newPosition) {
          const elevation = await getElevation(newPosition);
          updateCoordinates(
            newPosition.lat as number,
            newPosition.lng as number,
            elevation
          );
        }
      });

      marker.value = markerInstance;
    } catch (error) {
      console.error('Error initializing map:', error);
    }
  }

  async function searchCountries(searchCountry: string) {
    if (!searchCountry) {
      loadingCountries.value = false;
      return;
    }

    if (!autocompleteService.value)
      return;

    try {
      loadingCountries.value = true;
      const { AutocompleteSuggestion } = await google.maps.importLibrary('places');
      const request = {
        input: searchCountry,
        includedPrimaryTypes: ['country'],
        language: 'en'
      };

      const suggestions = await AutocompleteSuggestion.fetchAutocompleteSuggestions(request);
      countries.value = suggestions.suggestions.map((suggestion) => {
        return {
          value: suggestion.placePrediction.text.text,
          label: suggestion.placePrediction.text.text
        };
      });
    } catch (err) {
      console.error('Error fetching countries:', err);
    } finally {
      loadingCountries.value = false;
    }
  }

  async function getCountryCode(address: string) {
    let countryCode = null;

    const { Geocoder } = await loader.importLibrary('geocoding');
    const geocoder = new Geocoder();
    const geocoderCountry = await geocoder.geocode({ address, language: 'en' });

    for (const result of geocoderCountry.results) {
      if (result.types.includes('country')) {
        for (const addressComponent of result.address_components) {
          if (addressComponent.types.includes('country')) {
            countryCode = addressComponent.short_name;
            break;
          }
        }
      }
    }

    return countryCode;
  }

  async function searchCities(searchCity: string) {
    if (!searchCity) {
      loadingCities.value = false;
      return;
    }

    if (!autocompleteService.value || !countryModel.value)
      return;

    try {
      loadingCities.value = true;
      const countryCode = await getCountryCode(countryModel.value);
      if (countryCode) {
        const { AutocompleteSuggestion } = await google.maps.importLibrary('places');
        const request = {
          input: searchCity,
          includedPrimaryTypes: ['locality'],
          includedRegionCodes: [countryCode],
          language: 'en'
        };

        const suggestions = await AutocompleteSuggestion.fetchAutocompleteSuggestions(request);
        cities.value = suggestions.suggestions.map((suggestion) => {
          const cityName = suggestion.placePrediction.mainText?.text;
          return {
            value: cityName,
            label: cityName
          };
        });
      }
    } catch (err) {
      console.error('Error fetching cities:', err);
    } finally {
      loadingCities.value = false;
    }
  }

  function getCurrentPosition() {
    loadingPosition.value = true;

    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        async (geolocationPosition: GeolocationPosition) => {
          const position = {
            lat: geolocationPosition.coords.latitude,
            lng: geolocationPosition.coords.longitude
          };

          if (isNaN(position.lat) || isNaN(position.lng)) {
            addToast(
              'error',
              'Location Error',
              'The Geolocation service failed.'
            );
            loadingPosition.value = false;
            return;
          }

          const elevation = await getElevation(position);
          updateCoordinates(
            position.lat as number,
            position.lng as number,
            elevation
          );

          if (marker.value)
            marker.value.position = new google.maps.LatLng(position.lat, position.lng);

          const { Geocoder } = await loader.importLibrary('geocoding');
          const geocoder = new Geocoder();
          const geocoderPosition = await geocoder.geocode({ location: position, language: 'en' });

          if (geocoderPosition.results.length > 0) {
            const country = geocoderPosition.results[0].address_components.find((component) => component.types.includes('country'));
            if (country) {
              await searchCountries(country.long_name);
              countryModel.value = country.long_name;

              const city = geocoderPosition.results[0].address_components.find((component) => component.types.includes('locality'));
              if (city) {
                await nextTick();
                await searchCities(city.long_name);
                cityModel.value = city.long_name;
              }
            }

            displayMap.value = true;
          }

          map.value?.setCenter(position);
          map.value?.setZoom(12);

          loadingPosition.value = false;
        },
        (error) => {
          addToast(
            'error',
            'Location Error',
            error.message || 'The Geolocation service failed.'
          );
          loadingPosition.value = false;
        },
        { timeout: 5000, maximumAge: 0 }
      );
    } else {
      addToast(
        'error',
        'Location Error',
        'Your browser does not support Geolocation.'
      );
      loadingPosition.value = false;
    }
  }

  function manualCoordinateChanges() {
    if (marker.value) {
      if (isValidCoordinate(latitudeModel.value) && isValidCoordinate(longitudeModel.value)) {
        const position = new google.maps.LatLng(latitudeModel.value, longitudeModel.value);
        marker.value.position = position;

        map.value?.setCenter(position);
        map.value?.setZoom(12);
      } else
        marker.value.position = null;
    }
  }

  function clearCoordinates() {
    updateCoordinates(null, null, null);

    if (marker.value)
      marker.value.position = null;

    map.value?.setCenter(new google.maps.LatLng(0, 0));
    map.value?.setZoom(2);

    displayMap.value = false;
  }

  onMounted(async () => {
    await loader.importLibrary('places');
    autocompleteService.value = true;

    await initMap();

    if (countryModel.value) {
      await searchCountries(countryModel.value);

      if (cityModel.value)
        await searchCities(cityModel.value);
    }

    if (isValidCoordinate(latitudeModel.value) && isValidCoordinate(longitudeModel.value))
      displayMap.value = true;
  });
</script>

<style scoped>
</style>
