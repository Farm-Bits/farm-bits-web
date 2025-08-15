<template>
  <div class="form-section">
    <!-- Current Location Button -->
    <div class="flex justify-start">
      <CLoadingButton
        class="btn-gradient-blue btn-small transform hover:scale-[1.02] inline-flex items-center"
        @click="getCurrentPosition"
        :loading="loadingPosition">
        <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
        </svg>
        Use Current Location
      </CLoadingButton>
    </div>

    <!-- Location Selection Grid -->
    <div class="form-grid">
      <!-- Country Selection -->
      <div class="form-field">
        <label for="country" class="form-label">
          Country *
        </label>
        <div class="relative">
          <CMultiSelect
            id="country"
            placeholder="Type to search country..."
            search="external"
            search-no-results-label=""
            options-style="text"
            :name="`${nameAttribute}[country]`"
            :multiple="false"
            :options="countries"
            :loading="loadingCountries"
            :disabled="!autocompleteService"
            @change="onCountryChange"
            @filter-change="searchCountries"
            class="form-input" />
        </div>
      </div>

      <!-- City Selection -->
      <div class="form-field">
        <label for="city" class="form-label">
          City
        </label>
        <div class="relative">
          <CMultiSelect
            id="city"
            :placeholder="!country ? 'Select country first' : 'Type to search city...'"
            search="external"
            search-no-results-label=""
            options-style="text"
            :name="`${nameAttribute}[city]`"
            :multiple="false"
            :options="cities"
            :loading="loadingCities"
            :disabled="!autocompleteService || !country"
            @change="onCityChange"
            @filter-change="searchCities"
            class="form-input" />
        </div>
      </div>
    </div>

    <!-- Coordinates and Map Section -->
    <div class="">
      <div class="form-grid-3">
        <!-- Coordinate Inputs -->
        <div class="form-field">
          <label for="latitude" class="form-label">
            Latitude
          </label>
          <div class="relative">
            <CFormInput
              id="latitude"
              placeholder="e.g., 40.7128"
              :name="`${nameAttribute}[latitude]`"
              type="number"
              step="any"
              v-model="latitudeModel"
              @change="manualCoordinateChanges"
              class="form-input" />
          </div>
        </div>

        <div class="form-field">
          <label for="longitude" class="form-label">
            Longitude
          </label>
          <div class="relative">
            <CFormInput
              id="longitude"
              placeholder="e.g., -74.0060"
              :name="`${nameAttribute}[longitude]`"
              type="number"
              step="any"
              v-model="longitudeModel"
              @change="manualCoordinateChanges"
              class="form-input" />
          </div>
        </div>

        <div class="form-field">
          <label for="altitude" class="form-label">
            Altitude (meters)
          </label>
          <div class="relative">
            <CFormInput
              id="altitude"
              placeholder="e.g., 150"
              :name="`${nameAttribute}[altitude]`"
              type="number"
              step="any"
              v-model="altitudeModel"
              class="form-input" />
          </div>
        </div>
      </div>

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
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed, onMounted, ref, watch } from 'vue';
  import { Loader } from '@googlemaps/js-api-loader';
  import useToastStore from '@/stores/toast';

  const props = defineProps<{
    nameAttribute: string;
    country: string | null;
    city: string | null;
    latitude: number | null;
    longitude: number | null;
    altitude: number | null;
  }>();

  const API_KEY = '***REMOVED***';

  const preSelectedCity = ref(props.city);
  const mapContainer = ref<HTMLElement | null>(null);
  const map = ref<google.maps.Map | null>(null);
  const marker = ref<google.maps.marker.AdvancedMarkerElement | null>(null);
  const autocompleteService = ref<boolean>(false);
  const countries = ref<{ value: string; label: string }[]>([]);
  const cities = ref<{ value: string; label: string }[]>([]);
  const loadingPosition = ref(false);
  const loadingCountries = ref(true);
  const loadingCities = ref(true);

  const loader = new Loader({
    apiKey: API_KEY,
    version: 'weekly'
  });

  const { addToast } = useToastStore();

  const emit = defineEmits<{
    'update:country': [value: string | null];
    'update:city': [value: string | null];
    'update:latitude': [value: number | null];
    'update:longitude': [value: number | null];
    'update:altitude': [value: number | null];
  }>();

  const countryModel = computed({
    get: () => props.country,
    set: (value: string | null) => emit('update:country', value)
  });

  const cityModel = computed({
    get: () => props.city,
    set: (value: string | null) => emit('update:city', value)
  });

  const latitudeModel = computed({
    get: () => props.latitude,
    set: (value: string | number | null) => {
      if (value == null) {
        emit('update:latitude', value);
      } else {
        const newValue = typeof value === 'string' ? parseFloat(value) : value;
        if (isNaN(newValue)) {
          emit('update:latitude', null);
        } else {
          emit('update:latitude', newValue);
        }
      }
    }
  });

  const longitudeModel = computed({
    get: () => props.longitude,
    set: (value: string | number | null) => {
      if (value == null) {
        emit('update:longitude', value);
      } else {
        const newValue = typeof value === 'string' ? parseFloat(value) : value;
        if (isNaN(newValue)) {
          emit('update:longitude', null);
        } else {
          emit('update:longitude', newValue);
        }
      }
    }
  });

  const altitudeModel = computed({
    get: () => props.altitude,
    set: (value: string | number | null) => {
      const newValue = typeof value === 'string' ? parseFloat(value) : value;
      emit('update:altitude', newValue);
    }
  });

  async function getElevation(position: google.maps.LatLng | google.maps.LatLngLiteral | google.maps.LatLngAltitudeLiteral) {
    const elevationService = new google.maps.ElevationService();
    const elevation = await elevationService.getElevationForLocations({
      locations: [position]
    });
    return elevation.results[0]?.elevation;
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

      if (latitudeModel.value != null && longitudeModel.value != null) {
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
          latitudeModel.value = newPosition.lat as number;
          longitudeModel.value = newPosition.lng as number;
          altitudeModel.value = await getElevation(newPosition);
        }
      });

      marker.value = markerInstance;
    } catch (error) {
      console.error('Error initializing map:', error);
    }
  }

  function onCountryChange(selectedOptions: { value: string; label: string }[]) {
    cityModel.value = null;
    cities.value = [];
    if (selectedOptions.length === 1)
      countryModel.value = selectedOptions[0].value;
    else
      countryModel.value = null;
  }

  function onCityChange(selectedOptions: { value: string; label: string }[]) {
    if (selectedOptions.length === 1)
      cityModel.value = selectedOptions[0].value;
    else
      cityModel.value = null;
  }

  async function searchCountries(searchCountry: string, selectExactMatch: boolean = false) {
    if (!searchCountry) {
      loadingCountries.value = true;
      countries.value = [];
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
        const selected = selectExactMatch && suggestion.placePrediction.text.text === searchCountry;
        return {
          value: suggestion.placePrediction.text.text,
          label: suggestion.placePrediction.text.text,
          selected
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

  async function searchCities(searchCity: string, selectExactMatch: boolean = false) {
    if (!searchCity) {
      loadingCities.value = true;
      cities.value = [];
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
          const selected = selectExactMatch && cityName === searchCity;
          return {
            value: cityName,
            label: cityName,
            selected
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

          latitudeModel.value = position.lat;
          longitudeModel.value = position.lng;
          altitudeModel.value = await getElevation(position);

          if (marker.value)
            marker.value.position = new google.maps.LatLng(position.lat, position.lng);

          const { Geocoder } = await loader.importLibrary('geocoding');
          const geocoder = new Geocoder();
          const geocoderPosition = await geocoder.geocode({ location: position, language: 'en' });

          if (geocoderPosition.results.length > 0) {
            const country = geocoderPosition.results[0].address_components.find((component) => component.types.includes('country'));
            if (country) {
              const city = geocoderPosition.results[0].address_components.find((component) => component.types.includes('locality'));
              if (city)
                preSelectedCity.value = city.long_name;
              searchCountries(country.long_name, true);
            }
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
      if (latitudeModel.value != null && longitudeModel.value != null) {
        const position = new google.maps.LatLng(latitudeModel.value, longitudeModel.value);
        marker.value.position = position;

        map.value?.setCenter(position);
        map.value?.setZoom(12);
      } else
        marker.value.position = null;
    }
  }

  function initCity(country: string | null) {
    if (country && preSelectedCity.value)
      searchCities(preSelectedCity.value, true);
    preSelectedCity.value = null;
  }

  watch(() => countryModel.value, initCity);

  onMounted(async () => {
    await loader.importLibrary('places');
    autocompleteService.value = true;

    await initMap();

    if (countryModel.value) {
      await searchCountries(countryModel.value, true);
      initCity(countryModel.value);
    }
  });
</script>

<style scoped>
</style>
