<template>
  <Teleport to="body">
    <div v-if="show" class="fixed inset-0 z-50 overflow-y-auto">
      <!-- Backdrop -->
      <div class="fixed inset-0 bg-black bg-opacity-50 transition-opacity" @click="$emit('close')"></div>
      
      <!-- Modal -->
      <div class="flex min-h-full items-center justify-center p-4">
        <div class="relative w-full max-w-6xl bg-white rounded-2xl shadow-2xl transform transition-all max-h-[90vh] overflow-hidden">
          <!-- Header -->
          <div class="sticky top-0 bg-gradient-to-r from-blue-500 to-purple-500 px-8 py-6 z-10">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-3">
                <div class="bg-white bg-opacity-20 p-2 rounded-full">
                  <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                  </svg>
                </div>
                <div>
                  <h2 class="text-2xl font-bold text-white">{{ protocol?.name }}</h2>
                  <p class="text-blue-100 text-sm">Protocol Details</p>
                </div>
              </div>
              <div class="flex items-center space-x-2">
                <button
                  @click="$emit('edit', protocol)"
                  class="text-white hover:bg-white hover:bg-opacity-20 p-2 rounded-full transition-colors"
                  title="Edit Protocol"
                >
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                  </svg>
                </button>
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
          </div>

          <!-- Content -->
          <div class="overflow-y-auto max-h-[calc(90vh-100px)]">
            <div class="p-8 space-y-8">
              <!-- Protocol Overview -->
              <div class="bg-gradient-to-r from-gray-50 to-blue-50 rounded-xl p-6">
                <h3 class="text-lg font-semibold text-gray-800 mb-6 flex items-center">
                  <svg class="w-5 h-5 mr-2 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                  </svg>
                  Protocol Overview
                </h3>
                
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  <div class="bg-white rounded-lg p-4 shadow-sm">
                    <div class="flex items-center justify-between mb-2">
                      <span class="text-sm text-gray-600">Status</span>
                      <div class="flex items-center space-x-1">
                        <div class="w-2 h-2 rounded-full" :class="protocol?.active ? 'bg-green-500' : 'bg-red-500'"></div>
                        <span class="text-sm font-medium" :class="protocol?.active ? 'text-green-700' : 'text-red-700'">
                          {{ protocol?.active ? 'Active' : 'Inactive' }}
                        </span>
                      </div>
                    </div>
                  </div>
                  
                  <div class="bg-white rounded-lg p-4 shadow-sm">
                    <div class="flex items-center justify-between mb-2">
                      <span class="text-sm text-gray-600">Protocol Type</span>
                      <span class="text-sm font-medium text-gray-800">{{ protocol?.protocol_type || 'Standard' }}</span>
                    </div>
                  </div>
                  
                  <div class="bg-white rounded-lg p-4 shadow-sm">
                    <div class="flex items-center justify-between mb-2">
                      <span class="text-sm text-gray-600">Subtype</span>
                      <span class="text-sm font-medium text-gray-800">{{ protocol?.protocol_subtype || 'N/A' }}</span>
                    </div>
                  </div>
                  
                  <div class="bg-white rounded-lg p-4 shadow-sm">
                    <div class="flex items-center justify-between mb-2">
                      <span class="text-sm text-gray-600">Crop Type</span>
                      <span class="text-sm font-medium text-gray-800">{{ getCropTypeName(protocol?.crop_type_id) }}</span>
                    </div>
                  </div>
                  
                  <div class="bg-white rounded-lg p-4 shadow-sm">
                    <div class="flex items-center justify-between mb-2">
                      <span class="text-sm text-gray-600">Total Days</span>
                      <span class="text-sm font-medium text-gray-800">{{ protocol?.protocol_days?.length || 0 }}</span>
                    </div>
                  </div>
                  
                  <div class="bg-white rounded-lg p-4 shadow-sm">
                    <div class="flex items-center justify-between mb-2">
                      <span class="text-sm text-gray-600">Created</span>
                      <span class="text-sm font-medium text-gray-800">{{ formatDate(protocol?.created_at) }}</span>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Protocol Days -->
              <div v-if="protocol?.protocol_days?.length > 0" class="bg-gray-50 rounded-xl p-6">
                <div class="flex items-center justify-between mb-6">
                  <h3 class="text-lg font-semibold text-gray-800 flex items-center">
                    <svg class="w-5 h-5 mr-2 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                    </svg>
                    Protocol Days Configuration
                  </h3>
                  <span class="bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm font-medium">
                    {{ protocol.protocol_days.length }} Days
                  </span>
                </div>

                <div class="space-y-4 max-h-96 overflow-y-auto">
                  <div
                    v-for="(day, index) in protocol.protocol_days"
                    :key="index"
                    class="bg-white rounded-lg border border-gray-200 p-6 hover:shadow-md transition-shadow duration-200"
                  >
                    <div class="flex items-center justify-between mb-4">
                      <h4 class="text-lg font-semibold text-gray-800 flex items-center">
                        <span class="bg-gradient-to-r from-green-500 to-blue-500 text-white px-3 py-1 rounded-full text-sm font-bold mr-3">
                          Day {{ day.day_number || index + 1 }}
                        </span>
                        <div class="flex items-center space-x-4 text-sm">
                          <span class="bg-gray-100 px-2 py-1 rounded-lg">{{ formatDeviceType(day.lcd_subtype) }}</span>
                          <span class="bg-gray-100 px-2 py-1 rounded-lg">{{ formatOperationMode(day.operation_mode) }}</span>
                        </div>
                      </h4>
                    </div>

                    <!-- Environmental Controls Grid -->
                    <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4 mb-4">
                      <div v-if="day.temperature_day !== null" class="bg-gradient-to-r from-red-50 to-orange-50 rounded-lg p-3">
                        <div class="text-xs text-gray-600 mb-1 flex items-center">
                          <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707"></path>
                          </svg>
                          Temp Day
                        </div>
                        <div class="text-lg font-bold text-red-600">{{ day.temperature_day }}°C</div>
                      </div>
                      
                      <div v-if="day.temperature_night !== null" class="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-lg p-3">
                        <div class="text-xs text-gray-600 mb-1 flex items-center">
                          <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"></path>
                          </svg>
                          Temp Night
                        </div>
                        <div class="text-lg font-bold text-blue-600">{{ day.temperature_night }}°C</div>
                      </div>
                      
                      <div v-if="day.humidity_day !== null" class="bg-gradient-to-r from-cyan-50 to-teal-50 rounded-lg p-3">
                        <div class="text-xs text-gray-600 mb-1 flex items-center">
                          <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z"></path>
                          </svg>
                          Humidity Day
                        </div>
                        <div class="text-lg font-bold text-cyan-600">{{ day.humidity_day }}%</div>
                      </div>
                      
                      <div v-if="day.humidity_night !== null" class="bg-gradient-to-r from-cyan-50 to-teal-50 rounded-lg p-3">
                        <div class="text-xs text-gray-600 mb-1 flex items-center">
                          <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z"></path>
                          </svg>
                          Humidity Night
                        </div>
                        <div class="text-lg font-bold text-teal-600">{{ day.humidity_night }}%</div>
                      </div>
                      
                      <div v-if="day.co2_day !== null" class="bg-gradient-to-r from-green-50 to-emerald-50 rounded-lg p-3">
                        <div class="text-xs text-gray-600 mb-1 flex items-center">
                          <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
                          </svg>
                          CO2 Day
                        </div>
                        <div class="text-lg font-bold text-green-600">{{ day.co2_day }} ppm</div>
                      </div>
                      
                      <div v-if="day.co2_night !== null" class="bg-gradient-to-r from-green-50 to-emerald-50 rounded-lg p-3">
                        <div class="text-xs text-gray-600 mb-1 flex items-center">
                          <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
                          </svg>
                          CO2 Night
                        </div>
                        <div class="text-lg font-bold text-emerald-600">{{ day.co2_night }} ppm</div>
                      </div>
                      
                      <div v-if="day.radiation_day !== null" class="bg-gradient-to-r from-yellow-50 to-amber-50 rounded-lg p-3">
                        <div class="text-xs text-gray-600 mb-1 flex items-center">
                          <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707"></path>
                          </svg>
                          Radiation Day
                        </div>
                        <div class="text-lg font-bold text-yellow-600">{{ day.radiation_day }}</div>
                      </div>
                      
                      <div v-if="day.soil_moisture_day !== null" class="bg-gradient-to-r from-brown-50 to-amber-50 rounded-lg p-3">
                        <div class="text-xs text-gray-600 mb-1 flex items-center">
                          <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z"></path>
                          </svg>
                          Soil Moisture
                        </div>
                        <div class="text-lg font-bold text-amber-600">{{ day.soil_moisture_day }}%</div>
                      </div>
                    </div>

                    <!-- Duty Cycle and Timing -->
                    <div v-if="day.dc_on || day.dc_off || day.duration1 || day.duration2 || day.duration3" class="border-t border-gray-200 pt-4">
                      <h5 class="text-sm font-medium text-gray-700 mb-3 flex items-center">
                        <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                        </svg>
                        Timing & Control Settings
                      </h5>
                      <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-3">
                        <div v-if="day.dc_on !== null" class="bg-purple-50 rounded-lg p-3 text-center">
                          <div class="text-xs text-gray-600 mb-1">DC On</div>
                          <div class="text-sm font-bold text-purple-600">{{ day.dc_on }} min</div>
                        </div>
                        
                        <div v-if="day.dc_off !== null" class="bg-purple-50 rounded-lg p-3 text-center">
                          <div class="text-xs text-gray-600 mb-1">DC Off</div>
                          <div class="text-sm font-bold text-purple-600">{{ day.dc_off }} min</div>
                        </div>
                        
                        <div v-if="day.duration1 !== null" class="bg-indigo-50 rounded-lg p-3 text-center">
                          <div class="text-xs text-gray-600 mb-1">Duration 1</div>
                          <div class="text-sm font-bold text-indigo-600">{{ day.duration1 }} min</div>
                          <div v-if="day.starting_time1" class="text-xs text-gray-500 mt-1">{{ day.starting_time1 }}</div>
                        </div>
                        
                        <div v-if="day.duration2 !== null" class="bg-indigo-50 rounded-lg p-3 text-center">
                          <div class="text-xs text-gray-600 mb-1">Duration 2</div>
                          <div class="text-sm font-bold text-indigo-600">{{ day.duration2 }} min</div>
                          <div v-if="day.starting_time2" class="text-xs text-gray-500 mt-1">{{ day.starting_time2 }}</div>
                        </div>
                        
                        <div v-if="day.duration3 !== null" class="bg-indigo-50 rounded-lg p-3 text-center">
                          <div class="text-xs text-gray-600 mb-1">Duration 3</div>
                          <div class="text-sm font-bold text-indigo-600">{{ day.duration3 }} min</div>
                          <div v-if="day.starting_time3" class="text-xs text-gray-500 mt-1">{{ day.starting_time3 }}</div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Empty State for No Days -->
              <div v-else class="text-center py-12">
                <div class="bg-gradient-to-r from-gray-50 to-blue-50 rounded-xl p-12">
                  <svg class="w-16 h-16 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                  </svg>
                  <h3 class="text-lg font-semibold text-gray-800 mb-2">No Protocol Days Configured</h3>
                  <p class="text-gray-600 mb-4">This protocol doesn't have any days configured yet</p>
                  <button
                    @click="$emit('edit', protocol)"
                    class="bg-gradient-to-r from-green-500 to-green-600 text-white px-6 py-2 rounded-xl font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200"
                  >
                    Configure Days
                  </button>
                </div>
              </div>

              <!-- Protocol Statistics -->
              <div v-if="protocol?.protocol_days?.length > 0" class="bg-gradient-to-r from-purple-50 to-pink-50 rounded-xl p-6">
                <h3 class="text-lg font-semibold text-gray-800 mb-6 flex items-center">
                  <svg class="w-5 h-5 mr-2 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
                  </svg>
                  Protocol Statistics
                </h3>
                
                <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div class="bg-white rounded-lg p-4 text-center shadow-sm">
                    <div class="text-2xl font-bold text-red-500">{{ getAverageTemp('day') }}°C</div>
                    <div class="text-xs text-gray-600">Avg Day Temp</div>
                  </div>
                  
                  <div class="bg-white rounded-lg p-4 text-center shadow-sm">
                    <div class="text-2xl font-bold text-blue-500">{{ getAverageTemp('night') }}°C</div>
                    <div class="text-xs text-gray-600">Avg Night Temp</div>
                  </div>
                  
                  <div class="bg-white rounded-lg p-4 text-center shadow-sm">
                    <div class="text-2xl font-bold text-cyan-500">{{ getAverageHumidity('day') }}%</div>
                    <div class="text-xs text-gray-600">Avg Day Humidity</div>
                  </div>
                  
                  <div class="bg-white rounded-lg p-4 text-center shadow-sm">
                    <div class="text-2xl font-bold text-green-500">{{ getAverageCO2('day') }}</div>
                    <div class="text-xs text-gray-600">Avg CO2 ppm</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Footer -->
          <div class="sticky bottom-0 bg-white border-t border-gray-200 px-8 py-4 flex items-center justify-between">
            <div class="text-sm text-gray-500">
              Last updated: {{ formatDate(protocol?.updated_at) }}
            </div>
            <div class="flex space-x-3">
              <button
                @click="$emit('edit', protocol)"
                class="px-6 py-2 bg-gradient-to-r from-green-500 to-green-600 text-white rounded-lg font-semibold hover:from-green-600 hover:to-green-700 transform hover:scale-105 transition-all duration-200 shadow-md hover:shadow-lg"
              >
                Edit Protocol
              </button>
              <button
                @click="$emit('close')"
                class="px-6 py-2 border border-gray-300 rounded-lg text-gray-700 font-semibold hover:bg-gray-50 transition-colors duration-200"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
const props = defineProps({
  show: Boolean,
  protocol: Object,
  cropTypes: Array
})

defineEmits(['close', 'edit'])

// Methods
const getCropTypeName = (cropTypeId) => {
  if (!props.cropTypes || !cropTypeId) return 'Unknown'
  const cropType = props.cropTypes.find(ct => ct.id === cropTypeId)
  return cropType ? cropType.name : 'Unknown'
}

const formatDate = (dateString) => {
  if (!dateString) return 'N/A'
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatDeviceType = (device) => {
  const deviceMap = {
    'irrigation': 'Irrigation',
    'fans': 'Fans',
    'heater': 'Heater',
    'windows': 'Windows'
  }
  return deviceMap[device] || device || 'N/A'
}

const formatOperationMode = (mode) => {
  const modeMap = {
    'manual-on': 'Manual On',
    'manual-off': 'Manual Off',
    'temp-sp': 'Temperature SP',
    'humid-sp': 'Humidity SP',
    'duty-cycle': 'Duty Cycle',
    'fixed-settings': 'Fixed Settings'
  }
  return modeMap[mode] || mode || 'N/A'
}

const getAverageTemp = (period) => {
  if (!props.protocol?.protocol_days?.length) return 'N/A'
  
  const field = period === 'day' ? 'temperature_day' : 'temperature_night'
  const temps = props.protocol.protocol_days
    .map(day => day[field])
    .filter(temp => temp !== null && temp !== undefined)
  
  if (temps.length === 0) return 'N/A'
  
  const avg = temps.reduce((sum, temp) => sum + temp, 0) / temps.length
  return Math.round(avg * 10) / 10
}

const getAverageHumidity = (period) => {
  if (!props.protocol?.protocol_days?.length) return 'N/A'
  
  const field = period === 'day' ? 'humidity_day' : 'humidity_night'
  const humidities = props.protocol.protocol_days
    .map(day => day[field])
    .filter(humidity => humidity !== null && humidity !== undefined)
  
  if (humidities.length === 0) return 'N/A'
  
  const avg = humidities.reduce((sum, humidity) => sum + humidity, 0) / humidities.length
  return Math.round(avg)
}

const getAverageCO2 = (period) => {
  if (!props.protocol?.protocol_days?.length) return 'N/A'
  
  const field = period === 'day' ? 'co2_day' : 'co2_night'
  const co2Levels = props.protocol.protocol_days
    .map(day => day[field])
    .filter(co2 => co2 !== null && co2 !== undefined)
  
  if (co2Levels.length === 0) return 'N/A'
  
  const avg = co2Levels.reduce((sum, co2) => sum + co2, 0) / co2Levels.length
  return Math.round(avg)
}
</script>