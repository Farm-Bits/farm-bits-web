<template>
  <Teleport to="body">
    <div v-if="show" class="fixed inset-0 z-50 overflow-y-auto">
      <!-- Backdrop -->
      <div class="fixed inset-0 bg-black bg-opacity-50 transition-opacity" @click="$emit('close')"></div>
      
      <!-- Modal -->
      <div class="flex min-h-full items-center justify-center p-4">
        <div class="relative w-full max-w-6xl bg-white rounded-2xl shadow-2xl transform transition-all max-h-[90vh] overflow-hidden">
          <!-- Header -->
          <div class="sticky top-0 bg-gradient-to-r from-green-500 to-blue-500 px-8 py-6 z-10">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-3">
                <div class="bg-white bg-opacity-20 p-2 rounded-full">
                  <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                  </svg>
                </div>
                <h2 class="text-2xl font-bold text-white">
                  {{ isEditing ? 'Edit Protocol' : 'Create New Protocol' }}
                </h2>
              </div>
              <button
                @click="$emit('close')"
                class="text-white hover:bg-white hover:bg-opacity-20 p-2 rounded-full transition-colors"
              >
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>
          </div>

          <!-- Content -->
          <div class="overflow-y-auto max-h-[calc(90vh-100px)]">
            <form @submit.prevent="saveProtocol" class="p-8 space-y-8">
              <!-- Basic Information -->
              <div class="bg-gray-50 rounded-xl p-6">
                <h3 class="text-lg font-semibold text-gray-800 mb-6 flex items-center">
                  <svg class="w-5 h-5 mr-2 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                  </svg>
                  Basic Information
                </h3>
                
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div class="md:col-span-2">
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                      Protocol Name *
                    </label>
                    <input
                      v-model="form.name"
                      type="text"
                      required
                      class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
                      placeholder="Enter protocol name"
                    />
                  </div>
                  
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                      Crop Type *
                    </label>
                    <select
                      v-model="form.crop_type_id"
                      required
                      class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
                    >
                      <option value="">Select crop type</option>
                      <option v-for="cropType in cropTypes" :key="cropType.id" :value="cropType.id">
                        {{ cropType.name }}
                      </option>
                    </select>
                  </div>
                  
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                      Protocol Type
                    </label>
                    <select
                      v-model="form.protocol_type"
                      class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
                    >
                      <option value="Standard">Standard</option>
                      <option value="Express">Express</option>
                      <option value="Specialized">Specialized</option>
                      <option value="Experimental">Experimental</option>
                    </select>
                  </div>
                  
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                      Protocol Subtype
                    </label>
                    <input
                      v-model="form.protocol_subtype"
                      type="text"
                      class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
                      placeholder="e.g., Seasonal, Fast Growth"
                    />
                  </div>
                  
                  <div class="flex items-center">
                    <label class="flex items-center space-x-3 cursor-pointer">
                      <input
                        v-model="form.active"
                        type="checkbox"
                        class="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                      />
                      <span class="text-sm font-medium text-gray-700">Active Protocol</span>
                    </label>
                  </div>
                </div>
              </div>

              <!-- Protocol Days -->
              <div class="bg-gray-50 rounded-xl p-6">
                <div class="flex items-center justify-between mb-6">
                  <h3 class="text-lg font-semibold text-gray-800 flex items-center">
                    <svg class="w-5 h-5 mr-2 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                    </svg>
                    Protocol Days ({{ form.protocol_days.length }})
                  </h3>
                  <button
                    type="button"
                    @click="addProtocolDay"
                    class="bg-gradient-to-r from-green-500 to-green-600 text-white px-4 py-2 rounded-lg font-semibold hover:shadow-md transform hover:scale-105 transition-all duration-200 flex items-center space-x-2"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                    </svg>
                    <span>Add Day</span>
                  </button>
                </div>

                <div class="space-y-4 max-h-96 overflow-y-auto">
                  <div
                    v-for="(day, index) in form.protocol_days"
                    :key="index"
                    class="bg-white rounded-lg border border-gray-200 p-6 hover:shadow-md transition-shadow duration-200"
                  >
                    <div class="flex items-center justify-between mb-4">
                      <h4 class="text-md font-semibold text-gray-800">
                        Day {{ day.day_number || index + 1 }}
                      </h4>
                      <button
                        type="button"
                        @click="removeProtocolDay(index)"
                        class="text-red-500 hover:bg-red-50 p-2 rounded-lg transition-colors"
                        title="Remove Day"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                        </svg>
                      </button>
                    </div>

                    <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
                      <div>
                        <label class="block text-xs font-medium text-gray-600 mb-1">Day #</label>
                        <input
                          v-model.number="day.day_number"
                          type="number"
                          min="1"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                      </div>
                      
                      <div>
                        <label class="block text-xs font-medium text-gray-600 mb-1">Device</label>
                        <select
                          v-model="day.lcd_subtype"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        >
                          <option value="irrigation">Irrigation</option>
                          <option value="fans">Fans</option>
                          <option value="heater">Heater</option>
                          <option value="windows">Windows</option>
                        </select>
                      </div>
                      
                      <div>
                        <label class="block text-xs font-medium text-gray-600 mb-1">Mode</label>
                        <select
                          v-model="day.operation_mode"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        >
                          <option value="manual-on">Manual On</option>
                          <option value="manual-off">Manual Off</option>
                          <option value="temp-sp">Temp. SP</option>
                          <option value="humid-sp">Humidity SP</option>
                          <option value="duty-cycle">Duty Cycle</option>
                          <option value="fixed-settings">Fixed Settings</option>
                        </select>
                      </div>
                      
                      <div>
                        <label class="block text-xs font-medium text-gray-600 mb-1">Temp Day (°C)</label>
                        <input
                          v-model.number="day.temperature_day"
                          type="number"
                          step="0.1"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                      </div>
                      
                      <div>
                        <label class="block text-xs font-medium text-gray-600 mb-1">Temp Night (°C)</label>
                        <input
                          v-model.number="day.temperature_night"
                          type="number"
                          step="0.1"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                      </div>
                      
                      <div>
                        <label class="block text-xs font-medium text-gray-600 mb-1">Humidity Day (%)</label>
                        <input
                          v-model.number="day.humidity_day"
                          type="number"
                          min="0"
                          max="100"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                      </div>
                      
                      <div>
                        <label class="block text-xs font-medium text-gray-600 mb-1">Humidity Night (%)</label>
                        <input
                          v-model.number="day.humidity_night"
                          type="number"
                          min="0"
                          max="100"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                      </div>
                      
                      <div>
                        <label class="block text-xs font-medium text-gray-600 mb-1">CO2 Day (ppm)</label>
                        <input
                          v-model.number="day.co2_day"
                          type="number"
                          min="0"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                      </div>
                      
                      <div>
                        <label class="block text-xs font-medium text-gray-600 mb-1">CO2 Night (ppm)</label>
                        <input
                          v-model.number="day.co2_night"
                          type="number"
                          min="0"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                      </div>
                      
                      <div>
                        <label class="block text-xs font-medium text-gray-600 mb-1">Radiation Day</label>
                        <input
                          v-model.number="day.radiation_day"
                          type="number"
                          min="0"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                      </div>
                      
                      <div>
                        <label class="block text-xs font-medium text-gray-600 mb-1">Radiation Night</label>
                        <input
                          v-model.number="day.radiation_night"
                          type="number"
                          min="0"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                      </div>
                      
                      <div>
                        <label class="block text-xs font-medium text-gray-600 mb-1">Soil Moisture Day</label>
                        <input
                          v-model.number="day.soil_moisture_day"
                          type="number"
                          min="0"
                          max="100"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                      </div>
                      
                      <div>
                        <label class="block text-xs font-medium text-gray-600 mb-1">Soil Moisture Night</label>
                        <input
                          v-model.number="day.soil_moisture_night"
                          type="number"
                          min="0"
                          max="100"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                      </div>
                      
                      <div>
                        <label class="block text-xs font-medium text-gray-600 mb-1">DC On (min)</label>
                        <input
                          v-model.number="day.dc_on"
                          type="number"
                          min="0"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                      </div>
                      
                      <div>
                        <label class="block text-xs font-medium text-gray-600 mb-1">DC Off (min)</label>
                        <input
                          v-model.number="day.dc_off"
                          type="number"
                          min="0"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                      </div>
                    </div>

                    <!-- Timing Settings -->
                    <div class="mt-4 pt-4 border-t border-gray-200">
                      <h5 class="text-sm font-medium text-gray-700 mb-3">Timing Settings</h5>
                      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
                        <div>
                          <label class="block text-xs font-medium text-gray-600 mb-1">Duration 1 (min)</label>
                          <input
                            v-model.number="day.duration1"
                            type="number"
                            min="0"
                            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                          />
                        </div>
                        
                        <div>
                          <label class="block text-xs font-medium text-gray-600 mb-1">Start Time 1</label>
                          <input
                            v-model="day.starting_time1"
                            type="time"
                            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                          />
                        </div>
                        
                        <div>
                          <label class="block text-xs font-medium text-gray-600 mb-1">Duration 2 (min)</label>
                          <input
                            v-model.number="day.duration2"
                            type="number"
                            min="0"
                            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                          />
                        </div>
                        
                        <div>
                          <label class="block text-xs font-medium text-gray-600 mb-1">Start Time 2</label>
                          <input
                            v-model="day.starting_time2"
                            type="time"
                            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                          />
                        </div>
                        
                        <div>
                          <label class="block text-xs font-medium text-gray-600 mb-1">Duration 3 (min)</label>
                          <input
                            v-model.number="day.duration3"
                            type="number"
                            min="0"
                            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                          />
                        </div>
                        
                        <div>
                          <label class="block text-xs font-medium text-gray-600 mb-1">Start Time 3</label>
                          <input
                            v-model="day.starting_time3"
                            type="time"
                            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  <div v-if="form.protocol_days.length === 0" class="text-center py-8 text-gray-500">
                    <svg class="w-12 h-12 mx-auto mb-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                    </svg>
                    <p>No protocol days configured yet</p>
                    <p class="text-sm">Click "Add Day" to get started</p>
                  </div>
                </div>
              </div>

              <!-- Action Buttons -->
              <div class="sticky bottom-0 bg-white border-t border-gray-200 px-8 py-6 flex items-center justify-end space-x-4">
                <button
                  type="button"
                  @click="$emit('close')"
                  class="px-6 py-3 border border-gray-300 rounded-xl text-gray-700 font-semibold hover:bg-gray-50 transition-colors duration-200"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="px-6 py-3 bg-gradient-to-r from-green-500 to-green-600 text-white rounded-xl font-semibold hover:from-green-600 hover:to-green-700 transform hover:scale-105 transition-all duration-200 shadow-lg hover:shadow-xl"
                >
                  {{ isEditing ? 'Update Protocol' : 'Create Protocol' }}
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { ref, watch, nextTick } from 'vue'

const props = defineProps({
  show: Boolean,
  protocol: Object,
  cropTypes: Array,
  isEditing: Boolean
})

const emit = defineEmits(['close', 'save'])

// Form data
const form = ref({
  name: '',
  protocol_type: 'Standard',
  protocol_subtype: '',
  crop_type_id: '',
  active: true,
  protocol_days: []
})

// // Watch for prop changes
// watch(() => props.protocol, (newProtocol) => {
//   if (newProtocol) {
//     form.value = {
//       ...newProtocol,
//       protocol_days: newProtocol.protocol_days ? [...newProtocol.protocol_days] : []
//     }
//   } else {
//     resetForm()
//   }
// }, { immediate: true })

// watch(() => props.show, (newShow) => {
//   if (newShow && !props.isEditing) {
//     resetForm()
//   }
// })

// Methods
const resetForm = () => {
  form.value = {
    name: '',
    protocol_type: 'Standard',
    protocol_subtype: '',
    crop_type_id: '',
    active: true,
    protocol_days: []
  }
}

const addProtocolDay = () => {
  const newDay = {
    day_number: form.value.protocol_days.length + 1,
    crop_stage_id: null,
    lcd_subtype: 'irrigation',
    operation_mode: 'temp-sp',
    temperature_day: null,
    temperature_night: null,
    temperature_diff: null,
    humidity_day: null,
    humidity_night: null,
    humidity_diff: null,
    co2_day: null,
    co2_night: null,
    co2_diff: null,
    radiation_day: null,
    radiation_night: null,
    radiation_diff: null,
    soil_moisture_day: null,
    soil_moisture_night: null,
    soil_moisture_diff: null,
    dc_on: null,
    dc_off: null,
    duration1: null,
    starting_time1: '',
    duration2: null,
    starting_time2: '',
    duration3: null,
    starting_time3: ''
  }
  form.value.protocol_days.push(newDay)
}

const removeProtocolDay = (index) => {
  if (confirm('Are you sure you want to remove this day?')) {
    form.value.protocol_days.splice(index, 1)
    // Renumber the remaining days
    form.value.protocol_days.forEach((day, idx) => {
      day.day_number = idx + 1
    })
  }
}

const saveProtocol = () => {
  if (!form.value.name.trim()) {
    alert('Please enter a protocol name')
    return
  }
  
  if (!form.value.crop_type_id) {
    alert('Please select a crop type')
    return
  }

  // Convert crop_type_id to number
  const protocolData = {
    ...form.value,
    crop_type_id: parseInt(form.value.crop_type_id)
  }

  emit('save', protocolData)
}
</script>
