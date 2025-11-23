<template>
  <div class="bg-white rounded-xl shadow-lg border border-gray-200 p-6 hover:shadow-xl transition-all duration-300">
    <!-- Day Header -->
    <div class="flex items-center justify-between mb-6">
      <div class="flex items-center space-x-3">
        <div class="bg-gradient-to-r from-blue-500 to-purple-500 text-white px-4 py-2 rounded-full font-bold text-lg">
          Day {{ dayData.day_number }}
        </div>
        <div class="flex flex-col">
          <span class="text-sm text-gray-600">{{ formatDeviceType(dayData.lcd_subtype) }}</span>
          <span class="text-xs text-gray-500">{{ formatOperationMode(dayData.operation_mode) }}</span>
        </div>
      </div>
      
      <div class="flex items-center space-x-2">
        <button
          v-if="!isViewMode"
          @click="duplicateDay"
          class="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
          title="Duplicate Day"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
          </svg>
        </button>
        
        <button
          v-if="!isViewMode"
          @click="$emit('remove')"
          class="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
          title="Remove Day"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
          </svg>
        </button>

        <button
          @click="toggleExpanded"
          class="p-2 text-gray-600 hover:bg-gray-50 rounded-lg transition-colors"
          :title="isExpanded ? 'Collapse' : 'Expand'"
        >
          <svg
            class="w-4 h-4 transform transition-transform"
            :class="{ 'rotate-180': isExpanded }"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
          </svg>
        </button>
      </div>
    </div>

    <!-- Quick Overview Cards -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
      <div class="bg-gradient-to-r from-red-50 to-orange-50 rounded-lg p-3 text-center">
        <div class="text-xs text-gray-600 mb-1">Temperature</div>
        <div class="text-sm font-bold text-red-600">
          <span v-if="dayData.temperature_day">{{ dayData.temperature_day }}°C</span>
          <span v-if="dayData.temperature_day && dayData.temperature_night"> / </span>
          <span v-if="dayData.temperature_night" class="text-blue-600">{{ dayData.temperature_night }}°C</span>
          <span v-if="!dayData.temperature_day && !dayData.temperature_night" class="text-gray-400">N/A</span>
        </div>
      </div>
      
      <div class="bg-gradient-to-r from-cyan-50 to-teal-50 rounded-lg p-3 text-center">
        <div class="text-xs text-gray-600 mb-1">Humidity</div>
        <div class="text-sm font-bold text-cyan-600">
          <span v-if="dayData.humidity_day">{{ dayData.humidity_day }}%</span>
          <span v-if="dayData.humidity_day && dayData.humidity_night"> / </span>
          <span v-if="dayData.humidity_night" class="text-teal-600">{{ dayData.humidity_night }}%</span>
          <span v-if="!dayData.humidity_day && !dayData.humidity_night" class="text-gray-400">N/A</span>
        </div>
      </div>
      
      <div class="bg-gradient-to-r from-green-50 to-emerald-50 rounded-lg p-3 text-center">
        <div class="text-xs text-gray-600 mb-1">CO2</div>
        <div class="text-sm font-bold text-green-600">
          <span v-if="dayData.co2_day">{{ dayData.co2_day }}</span>
          <span v-if="dayData.co2_day && dayData.co2_night"> / </span>
          <span v-if="dayData.co2_night" class="text-emerald-600">{{ dayData.co2_night }}</span>
          <span v-if="!dayData.co2_day && !dayData.co2_night" class="text-gray-400">N/A</span>
        </div>
      </div>
      
      <div class="bg-gradient-to-r from-purple-50 to-indigo-50 rounded-lg p-3 text-center">
        <div class="text-xs text-gray-600 mb-1">Duty Cycle</div>
        <div class="text-sm font-bold text-purple-600">
          <span v-if="dayData.dc_on">{{ dayData.dc_on }}m</span>
          <span v-if="dayData.dc_on && dayData.dc_off"> / </span>
          <span v-if="dayData.dc_off" class="text-indigo-600">{{ dayData.dc_off }}m</span>
          <span v-if="!dayData.dc_on && !dayData.dc_off" class="text-gray-400">N/A</span>
        </div>
      </div>
    </div>

    <!-- Expanded Details -->
    <div v-if="isExpanded" class="space-y-6">
      <!-- Environmental Controls -->
      <div class="border-t pt-4">
        <h4 class="text-sm font-semibold text-gray-700 mb-3 flex items-center">
          <svg class="w-4 h-4 mr-2 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z"></path>
          </svg>
          Environmental Controls
        </h4>
        
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
          <!-- Temperature -->
          <div v-if="dayData.temperature_day || dayData.temperature_night" class="bg-red-50 rounded-lg p-3">
            <div class="text-xs text-gray-600 mb-2 font-medium">Temperature (°C)</div>
            <div class="space-y-1">
              <div v-if="dayData.temperature_day" class="flex justify-between text-sm">
                <span class="text-gray-600">Day:</span>
                <span class="font-semibold text-red-600">{{ dayData.temperature_day }}</span>
              </div>
              <div v-if="dayData.temperature_night" class="flex justify-between text-sm">
                <span class="text-gray-600">Night:</span>
                <span class="font-semibold text-blue-600">{{ dayData.temperature_night }}</span>
              </div>
              <div v-if="dayData.temperature_diff" class="flex justify-between text-sm">
                <span class="text-gray-600">Diff:</span>
                <span class="font-semibold text-orange-600">{{ dayData.temperature_diff }}</span>
              </div>
            </div>
          </div>

          <!-- Humidity -->
          <div v-if="dayData.humidity_day || dayData.humidity_night" class="bg-cyan-50 rounded-lg p-3">
            <div class="text-xs text-gray-600 mb-2 font-medium">Humidity (%)</div>
            <div class="space-y-1">
              <div v-if="dayData.humidity_day" class="flex justify-between text-sm">
                <span class="text-gray-600">Day:</span>
                <span class="font-semibold text-cyan-600">{{ dayData.humidity_day }}</span>
              </div>
              <div v-if="dayData.humidity_night" class="flex justify-between text-sm">
                <span class="text-gray-600">Night:</span>
                <span class="font-semibold text-teal-600">{{ dayData.humidity_night }}</span>
              </div>
              <div v-if="dayData.humidity_diff" class="flex justify-between text-sm">
                <span class="text-gray-600">Diff:</span>
                <span class="font-semibold text-cyan-700">{{ dayData.humidity_diff }}</span>
              </div>
            </div>
          </div>

          <!-- CO2 -->
          <div v-if="dayData.co2_day || dayData.co2_night" class="bg-green-50 rounded-lg p-3">
            <div class="text-xs text-gray-600 mb-2 font-medium">CO2 (ppm)</div>
            <div class="space-y-1">
              <div v-if="dayData.co2_day" class="flex justify-between text-sm">
                <span class="text-gray-600">Day:</span>
                <span class="font-semibold text-green-600">{{ dayData.co2_day }}</span>
              </div>
              <div v-if="dayData.co2_night" class="flex justify-between text-sm">
                <span class="text-gray-600">Night:</span>
                <span class="font-semibold text-emerald-600">{{ dayData.co2_night }}</span>
              </div>
              <div v-if="dayData.co2_diff" class="flex justify-between text-sm">
                <span class="text-gray-600">Diff:</span>
                <span class="font-semibold text-green-700">{{ dayData.co2_diff }}</span>
              </div>
            </div>
          </div>

          <!-- Radiation -->
          <div v-if="dayData.radiation_day || dayData.radiation_night" class="bg-yellow-50 rounded-lg p-3">
            <div class="text-xs text-gray-600 mb-2 font-medium">Radiation</div>
            <div class="space-y-1">
              <div v-if="dayData.radiation_day" class="flex justify-between text-sm">
                <span class="text-gray-600">Day:</span>
                <span class="font-semibold text-yellow-600">{{ dayData.radiation_day }}</span>
              </div>
              <div v-if="dayData.radiation_night" class="flex justify-between text-sm">
                <span class="text-gray-600">Night:</span>
                <span class="font-semibold text-yellow-700">{{ dayData.radiation_night }}</span>
              </div>
              <div v-if="dayData.radiation_diff" class="flex justify-between text-sm">
                <span class="text-gray-600">Diff:</span>
                <span class="font-semibold text-amber-600">{{ dayData.radiation_diff }}</span>
              </div>
            </div>
          </div>

          <!-- Soil Moisture -->
          <div v-if="dayData.soil_moisture_day || dayData.soil_moisture_night" class="bg-amber-50 rounded-lg p-3">
            <div class="text-xs text-gray-600 mb-2 font-medium">Soil Moisture (%)</div>
            <div class="space-y-1">
              <div v-if="dayData.soil_moisture_day" class="flex justify-between text-sm">
                <span class="text-gray-600">Day:</span>
                <span class="font-semibold text-amber-600">{{ dayData.soil_moisture_day }}</span>
              </div>
              <div v-if="dayData.soil_moisture_night" class="flex justify-between text-sm">
                <span class="text-gray-600">Night:</span>
                <span class="font-semibold text-amber-700">{{ dayData.soil_moisture_night }}</span>
              </div>
              <div v-if="dayData.soil_moisture_diff" class="flex justify-between text-sm">
                <span class="text-gray-600">Diff:</span>
                <span class="font-semibold text-orange-600">{{ dayData.soil_moisture_diff }}</span>
              </div>
            </div>
          </div>

          <!-- Duty Cycle -->
          <div v-if="dayData.dc_on || dayData.dc_off" class="bg-purple-50 rounded-lg p-3">
            <div class="text-xs text-gray-600 mb-2 font-medium">Duty Cycle (min)</div>
            <div class="space-y-1">
              <div v-if="dayData.dc_on" class="flex justify-between text-sm">
                <span class="text-gray-600">On:</span>
                <span class="font-semibold text-purple-600">{{ dayData.dc_on }}</span>
              </div>
              <div v-if="dayData.dc_off" class="flex justify-between text-sm">
                <span class="text-gray-600">Off:</span>
                <span class="font-semibold text-indigo-600">{{ dayData.dc_off }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Timing Schedule -->
      <div v-if="hasTimingData" class="border-t pt-4">
        <h4 class="text-sm font-semibold text-gray-700 mb-3 flex items-center">
          <svg class="w-4 h-4 mr-2 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          Timing Schedule
        </h4>
        
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div v-if="dayData.duration1 || dayData.starting_time1" class="bg-indigo-50 rounded-lg p-4">
            <div class="text-sm font-medium text-indigo-800 mb-2">Schedule 1</div>
            <div class="space-y-2">
              <div v-if="dayData.starting_time1" class="flex items-center text-sm text-gray-600">
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                Start: {{ dayData.starting_time1 }}
              </div>
              <div v-if="dayData.duration1" class="flex items-center text-sm text-gray-600">
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4v4m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                Duration: {{ dayData.duration1 }} min
              </div>
            </div>
          </div>
          
          <div v-if="dayData.duration2 || dayData.starting_time2" class="bg-indigo-50 rounded-lg p-4">
            <div class="text-sm font-medium text-indigo-800 mb-2">Schedule 2</div>
            <div class="space-y-2">
              <div v-if="dayData.starting_time2" class="flex items-center text-sm text-gray-600">
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                Start: {{ dayData.starting_time2 }}
              </div>
              <div v-if="dayData.duration2" class="flex items-center text-sm text-gray-600">
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4v4m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                Duration: {{ dayData.duration2 }} min
              </div>
            </div>
          </div>
          
          <div v-if="dayData.duration3 || dayData.starting_time3" class="bg-indigo-50 rounded-lg p-4">
            <div class="text-sm font-medium text-indigo-800 mb-2">Schedule 3</div>
            <div class="space-y-2">
              <div v-if="dayData.starting_time3" class="flex items-center text-sm text-gray-600">
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                Start: {{ dayData.starting_time3 }}
              </div>
              <div v-if="dayData.duration3" class="flex items-center text-sm text-gray-600">
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4v4m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                Duration: {{ dayData.duration3 }} min
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Device Configuration -->
      <div class="border-t pt-4">
        <h4 class="text-sm font-semibold text-gray-700 mb-3 flex items-center">
          <svg class="w-4 h-4 mr-2 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
          </svg>
          Device Configuration
        </h4>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="bg-gray-50 rounded-lg p-4">
            <div class="text-sm font-medium text-gray-700 mb-2">Device Type</div>
            <div class="text-lg font-semibold text-gray-800">{{ formatDeviceType(dayData.lcd_subtype) }}</div>
          </div>
          
          <div class="bg-gray-50 rounded-lg p-4">
            <div class="text-sm font-medium text-gray-700 mb-2">Operation Mode</div>
            <div class="text-lg font-semibold text-gray-800">{{ formatOperationMode(dayData.operation_mode) }}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Compact Mode Summary -->
    <div v-else class="mt-4 pt-4 border-t border-gray-100">
      <div class="flex items-center justify-between text-sm text-gray-600">
        <span>{{ getConfiguredParametersCount() }} parameters configured</span>
        <span class="text-blue-600 font-medium">Click to expand details</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  dayData: {
    type: Object,
    required: true
  },
  isViewMode: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['remove', 'duplicate'])

const isExpanded = ref(false)

// Computed properties
const hasTimingData = computed(() => {
  return props.dayData.duration1 || props.dayData.starting_time1 ||
         props.dayData.duration2 || props.dayData.starting_time2 ||
         props.dayData.duration3 || props.dayData.starting_time3
})

// Methods
const toggleExpanded = () => {
  isExpanded.value = !isExpanded.value
}

const duplicateDay = () => {
  emit('duplicate', props.dayData)
}

const formatDeviceType = (device) => {
  const deviceMap = {
    'irrigation': 'Irrigation System',
    'fans': 'Ventilation Fans',
    'heater': 'Heating System',
    'windows': 'Window Controls'
  }
  return deviceMap[device] || device || 'Unknown Device'
}

const formatOperationMode = (mode) => {
  const modeMap = {
    'manual-on': 'Manual On',
    'manual-off': 'Manual Off',
    'temp-sp': 'Temperature Setpoint',
    'humid-sp': 'Humidity Setpoint',
    'duty-cycle': 'Duty Cycle Control',
    'fixed-settings': 'Fixed Settings'
  }
  return modeMap[mode] || mode || 'Unknown Mode'
}

const getConfiguredParametersCount = () => {
  let count = 0
  const parameters = [
    'temperature_day', 'temperature_night', 'humidity_day', 'humidity_night',
    'co2_day', 'co2_night', 'radiation_day', 'radiation_night',
    'soil_moisture_day', 'soil_moisture_night', 'dc_on', 'dc_off',
    'duration1', 'duration2', 'duration3'
  ]
  
  parameters.forEach(param => {
    if (props.dayData[param] !== null && props.dayData[param] !== undefined && props.dayData[param] !== '') {
      count++
    }
  })
  
  return count
}
</script>
