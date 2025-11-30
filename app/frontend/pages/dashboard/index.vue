<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <header class="bg-white shadow-lg border-b border-gray-200">
      <div class="px-6 py-4">
        <div class="flex items-center justify-between">
          <h1 class="text-2xl font-bold text-gray-800">Sensors Management</h1>
          <button
            @click="showAddSensorModal = true"
            class="btn-primary btn-small"
          >
            Add New Sensor
          </button>
        </div>
      </div>
    </header>

    <div class="p-6">
      <!-- Filters and Search -->
      <div class="bg-white rounded-xl shadow-lg border border-gray-200 p-6 mb-6">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div class="form-field">
            <label class="form-label">Search</label>
            <input 
              v-model="searchQuery"
              type="text" 
              placeholder="Search sensors..."
              class="form-input"
            >
          </div>
          <div class="form-field">
            <label class="form-label">Status</label>
            <select v-model="statusFilter" class="form-input">
              <option value="">All Status</option>
              <option value="online">Online</option>
              <option value="offline">Offline</option>
              <option value="warning">Warning</option>
            </select>
          </div>
          <div class="form-field">
            <label class="form-label">Connection Type</label>
            <select v-model="connectionFilter" class="form-input">
              <option value="">All Types</option>
              <option value="DI">Digital Input (DI)</option>
              <option value="DO">Digital Output (DO)</option>
              <option value="AI">Analog Input (AI)</option>
              <option value="AO">Analog Output (AO)</option>
            </select>
          </div>
          <div class="form-field">
            <label class="form-label">PLC</label>
            <select v-model="plcFilter" class="form-input">
              <option value="">All PLCs</option>
              <option v-for="plc in plcs" :key="plc.id" :value="plc.id">{{ plc.name }}</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Sensors Grid -->
      <div class="sensor-grid">
        <div v-for="sensor in filteredSensors" :key="sensor.id" class="sensor-card">
          <div class="sensor-card-header">
            <div>
              <h3 class="sensor-title">{{ sensor.name }}</h3>
              <p class="sensor-subtitle">{{ sensor.location }}</p>
            </div>
            <div class="flex items-center space-x-2">
              <span :class="getStatusClass(sensor.status)">{{ sensor.status }}</span>
              <div class="flex space-x-1">
                <button 
                  @click="editSensor(sensor)"
                  class="text-blue-600 hover:text-blue-800 p-1"
                  title="Edit"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                  </svg>
                </button>
                <button 
                  @click="deleteSensor(sensor.id)"
                  class="text-red-600 hover:text-red-800 p-1"
                  title="Delete"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                  </svg>
                </button>
              </div>
            </div>
          </div>

          <div class="mb-4">
            <div class="sensor-value">{{ sensor.currentValue || '--' }}</div>
            <div class="sensor-unit">{{ sensor.unit }}</div>
          </div>

          <div class="space-y-2 text-sm text-gray-600">
            <div class="flex justify-between">
              <span>PLC:</span>
              <span>{{ getPLCName(sensor.plcId) }}</span>
            </div>
            <div class="flex justify-between">
              <span>Connection:</span>
              <span :class="getConnectionClass(sensor.connectionType)">{{ sensor.connectionType }}</span>
            </div>
            <div class="flex justify-between">
              <span>Address:</span>
              <span>{{ sensor.address }}</span>
            </div>
            <div class="flex justify-between">
              <span>Last Update:</span>
              <span>{{ formatTime(sensor.lastUpdate) }}</span>
            </div>
          </div>

          <!-- Control Section for DO/AO -->
          <div v-if="sensor.connectionType === 'DO' || sensor.connectionType === 'AO'" class="mt-4 pt-4 border-t border-gray-200">
            <div class="flex items-center justify-between mb-3">
              <span class="text-sm font-medium text-gray-700">Controls</span>
              <button
                @click="openControlModal(sensor)"
                class="text-blue-600 hover:text-blue-800 text-sm"
              >
                Configure
              </button>
            </div>

            <div v-if="sensor.connectionType === 'DO'" class="control-button-group">
              <button 
                @click="toggleOutput(sensor.id, true)"
                :class="sensor.outputState ? 'control-button-on' : 'bg-gray-300 text-gray-600 px-3 py-1 rounded text-sm'"
                :disabled="sensor.status === 'offline'"
              >
                ON
              </button>
              <button
                @click="toggleOutput(sensor.id, false)"
                :class="!sensor.outputState ? 'control-button-off' : 'bg-gray-300 text-gray-600 px-3 py-1 rounded text-sm'"
                :disabled="sensor.status === 'offline'"
              >
                OFF
              </button>
            </div>

            <div v-if="sensor.connectionType === 'AO'" class="space-y-2">
              <input
                v-model.number="sensor.outputValue"
                @change="setAnalogOutput(sensor.id, sensor.outputValue)"
                type="number"
                :min="sensor.minValue || 0"
                :max="sensor.maxValue || 100"
                class="w-full px-2 py-1 border border-gray-300 rounded text-sm"
                :disabled="sensor.status === 'offline'"
              >
              <div class="text-xs text-gray-500">
                Range: {{ sensor.minValue || 0 }} - {{ sensor.maxValue || 100 }} {{ sensor.unit }}
              </div>
            </div>
          </div>

          <!-- Analytics Button -->
          <div class="mt-4 pt-4 border-t border-gray-200">
            <button 
              @click="openAnalytics(sensor)"
              class="w-full bg-gray-100 hover:bg-gray-200 text-gray-700 py-2 px-4 rounded-lg text-sm font-medium transition-colors"
            >
              View Analytics
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Add/Edit Sensor Modal -->
    <div v-if="showAddSensorModal || showEditSensorModal" class="modal-overlay" @click.self="closeModals">
      <div class="modal-content">
        <div class="modal-header">
          <h2 class="modal-title">{{ showEditSensorModal ? 'Edit Sensor' : 'Add New Sensor' }}</h2>
          <button @click="closeModals" class="modal-close">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>

        <div class="modal-body">
          <form @submit.prevent="saveSensor" class="space-y-6">
            <div class="form-section">
              <h3 class="form-section-title">Basic Information</h3>
              <div class="form-row">
                <div class="form-field">
                  <label class="form-label">Sensor Name *</label>
                  <input
                    v-model="currentSensor.name"
                    type="text"
                    required
                    class="form-input"
                    placeholder="e.g., Temperature Sensor"
                  >
                </div>
                <div class="form-field">
                  <label class="form-label">Location</label>
                  <input
                    v-model="currentSensor.location"
                    type="text"
                    class="form-input"
                    placeholder="e.g., Room A1"
                  >
                </div>
              </div>
              <div class="form-field">
                <label class="form-label">Description</label>
                <textarea
                  v-model="currentSensor.description"
                  class="form-input"
                  rows="3"
                  placeholder="Optional description"
                ></textarea>
              </div>
            </div>

            <div class="form-section">
              <h3 class="form-section-title">PLC Connection</h3>
              <div class="form-row">
                <div class="form-field">
                  <label class="form-label">PLC *</label>
                  <select v-model="currentSensor.plcId" required class="form-input">
                    <option value="">Select PLC</option>
                    <option v-for="plc in plcs" :key="plc.id" :value="plc.id">{{ plc.name }}</option>
                  </select>
                </div>
                <div class="form-field">
                  <label class="form-label">Connection Type *</label>
                  <select v-model="currentSensor.connectionType" required class="form-input" @change="resetConnectionFields">
                    <option value="">Select Type</option>
                    <option value="DI">Digital Input (DI)</option>
                    <option value="DO">Digital Output (DO)</option>
                    <option value="AI">Analog Input (AI)</option>
                    <option value="AO">Analog Output (AO)</option>
                  </select>
                </div>
              </div>
              <div class="form-row">
                <div class="form-field">
                  <label class="form-label">Address *</label>
                  <input 
                    v-model="currentSensor.address"
                    type="text" 
                    required
                    class="form-input"
                    placeholder="e.g., I0.0, Q0.1, IW0, QW2"
                  >
                </div>
                <div class="form-field">
                  <label class="form-label">Unit</label>
                  <input
                    v-model="currentSensor.unit"
                    type="text"
                    class="form-input"
                    placeholder="e.g., °C, bar, L/min"
                  >
                </div>
              </div>
            </div>

            <!-- Analog-specific fields -->
            <div v-if="currentSensor.connectionType === 'AI' || currentSensor.connectionType === 'AO'" class="form-section">
              <h3 class="form-section-title">Analog Configuration</h3>
              <div class="form-row-3">
                <div class="form-field">
                  <label class="form-label">Min Value</label>
                  <input
                    v-model.number="currentSensor.minValue"
                    type="number"
                    step="0.01"
                    class="form-input"
                  >
                </div>
                <div class="form-field">
                  <label class="form-label">Max Value</label>
                  <input
                    v-model.number="currentSensor.maxValue"
                    type="number"
                    step="0.01"
                    class="form-input"
                  >
                </div>
                <div class="form-field">
                  <label class="form-label">Decimal Places</label>
                  <input
                    v-model.number="currentSensor.decimalPlaces"
                    type="number"
                    min="0"
                    max="4"
                    class="form-input"
                  >
                </div>
              </div>
            </div>
          </form>
        </div>

        <div class="modal-footer">
          <button @click="closeModals" type="button" class="btn-outline-secondary btn-small">
            Cancel
          </button>
          <button @click="saveSensor" type="button" class="btn-primary btn-small">
            {{ showEditSensorModal ? 'Update' : 'Add' }} Sensor
          </button>
        </div>
      </div>
    </div>

    <!-- Control Configuration Modal -->
    <div v-if="showControlModal" class="modal-overlay" @click.self="showControlModal = false">
      <div class="modal-content">
        <div class="modal-header">
          <h2 class="modal-title">Control Configuration - {{ selectedSensor?.name }}</h2>
          <button @click="showControlModal = false" class="modal-close">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>

        <div class="modal-body">
          <div class="space-y-6">
            <!-- Manual Control -->
            <div class="form-section">
              <h3 class="form-section-title">Manual Control</h3>
              <div v-if="selectedSensor?.connectionType === 'DO'" class="space-y-4">
                <div class="control-group">
                  <label class="flex items-center space-x-2">
                    <input type="radio" v-model="controlConfig.mode" value="manual" name="controlMode" class="form-check-input">
                    <span>Manual ON/OFF</span>
                  </label>
                </div>
                <div class="control-group">
                  <label class="flex items-center space-x-2">
                    <input type="radio" v-model="controlConfig.mode" value="timed" name="controlMode" class="form-check-input">
                    <span>Turn ON for specific duration</span>
                  </label>
                  <div v-if="controlConfig.mode === 'timed'" class="mt-2 ml-6">
                    <div class="form-row">
                      <div class="form-field">
                        <input
                          v-model.number="controlConfig.duration"
                          type="number"
                          min="1"
                          class="form-input"
                          placeholder="Duration"
                        >
                      </div>
                      <div class="form-field">
                        <select v-model="controlConfig.durationUnit" class="form-input">
                          <option value="seconds">Seconds</option>
                          <option value="minutes">Minutes</option>
                          <option value="hours">Hours</option>
                        </select>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="control-group">
                  <label class="flex items-center space-x-2">
                    <input type="radio" v-model="controlConfig.mode" value="counted" name="controlMode" class="form-check-input">
                    <span>Turn ON for specific amount</span>
                  </label>
                  <div v-if="controlConfig.mode === 'counted'" class="mt-2 ml-6">
                    <div class="form-row">
                      <div class="form-field">
                        <input
                          v-model.number="controlConfig.amount"
                          type="number"
                          min="1"
                          class="form-input"
                          placeholder="Amount"
                        >
                      </div>
                      <div class="form-field">
                        <select v-model="controlConfig.counterSensorId" class="form-input">
                          <option value="">Select Counter Sensor</option>
                          <option v-for="sensor in counterSensors" :key="sensor.id" :value="sensor.id">
                            {{ sensor.name }} ({{ sensor.unit }})
                          </option>
                        </select>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Scheduled Control -->
            <div class="form-section">
              <h3 class="form-section-title">Scheduled Control</h3>
              <div class="space-y-4">
                <div v-for="(schedule, index) in controlConfig.schedules" :key="index" class="schedule-item">
                  <div class="schedule-header">
                    <span class="schedule-type">Schedule {{ index + 1 }}</span>
                    <div class="schedule-actions">
                      <button @click="editSchedule(index)" class="text-blue-600 hover:text-blue-800 text-sm">Edit</button>
                      <button @click="removeSchedule(index)" class="text-red-600 hover:text-red-800 text-sm">Remove</button>
                    </div>
                  </div>
                  <div class="schedule-details">
                    <div class="schedule-time">{{ formatSchedule(schedule) }}</div>
                    <div>Action: {{ schedule.action }} for {{ schedule.duration }} {{ schedule.durationUnit }}</div>
                    <div v-if="schedule.repeat">Repeats: {{ schedule.repeatType }}</div>
                  </div>
                </div>

                <button
                  @click="addSchedule"
                  :disabled="controlConfig.schedules.length >= 5"
                  class="btn-outline btn-small"
                >
                  Add Schedule ({{ controlConfig.schedules.length }}/5)
                </button>
              </div>
            </div>

            <!-- Sensor-based Control -->
            <div class="form-section">
              <h3 class="form-section-title">Sensor-based Control</h3>
              <div class="space-y-4">
                <div v-for="(rule, index) in controlConfig.sensorRules" :key="index" class="schedule-item">
                  <div class="schedule-header">
                    <span class="schedule-type">Rule {{ index + 1 }}</span>
                    <button @click="removeSensorRule(index)" class="text-red-600 hover:text-red-800 text-sm">Remove</button>
                  </div>
                  <div class="schedule-details">
                    <div>{{ getSensorName(rule.sensorId) }}</div>
                    <div>{{ rule.action }} if {{ rule.condition }} {{ rule.value }} {{ getSensorUnit(rule.sensorId) }}</div>
                  </div>
                </div>

                <button @click="addSensorRule" class="btn-outline btn-small">
                  Add Sensor Rule
                </button>
              </div>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button @click="showControlModal = false" type="button" class="btn-outline-secondary btn-small">
            Cancel
          </button>
          <button @click="saveControlConfig" type="button" class="btn-primary btn-small">
            Save Configuration
          </button>
        </div>
      </div>
    </div>

    <!-- Analytics Modal -->
    <div v-if="showAnalyticsModal" class="modal-overlay" @click.self="showAnalyticsModal = false">
      <div class="modal-content" style="max-width: 1200px">
        <div class="modal-header">
          <h2 class="modal-title">Analytics - {{ selectedSensor?.name }}</h2>
          <button @click="showAnalyticsModal = false" class="modal-close">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>

        <div class="modal-body">
          <div class="chart-container">
            <div class="chart-header">
              <h3 class="chart-title">Historical Data</h3>
              <div class="chart-controls">
                <button
                  v-for="range in timeRanges"
                  :key="range.value"
                  @click="selectedTimeRange = range.value"
                  :class="selectedTimeRange === range.value ? 'time-range-button-active' : 'time-range-button'"
                >
                  {{ range.label }}
                </button>
              </div>
            </div>
            <div class="h-64 bg-gray-100 rounded-lg flex items-center justify-center">
              <span class="text-gray-500">Chart placeholder for {{ selectedTimeRange }}</span>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-6">
            <div class="widget">
              <h4 class="widget-title">Statistics</h4>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span>Average:</span>
                  <span class="font-medium">{{ analyticsData.average }} {{ selectedSensor?.unit }}</span>
                </div>
                <div class="flex justify-between">
                  <span>Minimum:</span>
                  <span class="font-medium">{{ analyticsData.min }} {{ selectedSensor?.unit }}</span>
                </div>
                <div class="flex justify-between">
                  <span>Maximum:</span>
                  <span class="font-medium">{{ analyticsData.max }} {{ selectedSensor?.unit }}</span>
                </div>
              </div>
            </div>

            <div class="widget">
              <h4 class="widget-title">Data Quality</h4>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span>Uptime:</span>
                  <span class="font-medium text-green-600">{{ analyticsData.uptime }}%</span>
                </div>
                <div class="flex justify-between">
                  <span>Data Points:</span>
                  <span class="font-medium">{{ analyticsData.dataPoints }}</span>
                </div>
                <div class="flex justify-between">
                  <span>Missing Data:</span>
                  <span class="font-medium">{{ analyticsData.missingData }}%</span>
                </div>
              </div>
            </div>

            <div class="widget">
              <h4 class="widget-title">Alerts</h4>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span>Total Alerts:</span>
                  <span class="font-medium">{{ analyticsData.totalAlerts }}</span>
                </div>
                <div class="flex justify-between">
                  <span>High Priority:</span>
                  <span class="font-medium text-red-600">{{ analyticsData.highAlerts }}</span>
                </div>
                <div class="flex justify-between">
                  <span>Last Alert:</span>
                  <span class="font-medium">{{ analyticsData.lastAlert }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'

interface Sensor {
  id: string
  name: string
  location: string
  description?: string
  plcId: string
  connectionType: 'DI' | 'DO' | 'AI' | 'AO'
  address: string
  unit: string
  status: 'online' | 'offline' | 'warning'
  currentValue?: number
  outputState?: boolean
  outputValue?: number
  minValue?: number
  maxValue?: number
  decimalPlaces?: number
  lastUpdate: Date
}

interface PLC {
  id: string
  name: string
  ip: string
  type: string
  connected: boolean
}

interface Schedule {
  id: string
  action: 'on' | 'off'
  duration: number
  durationUnit: 'seconds' | 'minutes' | 'hours'
  startTime: string
  date?: string
  repeat: boolean
  repeatType?: 'daily' | 'weekly' | 'monthly'
  dutyCycle?: {
    onDuration: number
    offDuration: number
    startHour: number
    endHour: number
  }
}

interface SensorRule {
  id: string
  sensorId: string
  condition: 'above' | 'below'
  value: number
  action: 'turn_on' | 'turn_off'
}

interface ControlConfig {
  mode: 'manual' | 'timed' | 'counted'
  duration?: number
  durationUnit?: 'seconds' | 'minutes' | 'hours'
  amount?: number
  counterSensorId?: string
  schedules: Schedule[]
  sensorRules: SensorRule[]
}

// Reactive data
const searchQuery = ref('')
const statusFilter = ref('')
const connectionFilter = ref('')
const plcFilter = ref('')

const showAddSensorModal = ref(false)
const showEditSensorModal = ref(false)
const showControlModal = ref(false)
const showAnalyticsModal = ref(false)

const selectedSensor = ref<Sensor | null>(null)
const selectedTimeRange = ref('24h')

const currentSensor = ref<Partial<Sensor>>({
  name: '',
  location: '',
  description: '',
  plcId: '',
  connectionType: undefined,
  address: '',
  unit: '',
  minValue: 0,
  maxValue: 100,
  decimalPlaces: 2
})

const controlConfig = ref<ControlConfig>({
  mode: 'manual',
  schedules: [],
  sensorRules: []
})

const plcs = ref<PLC[]>([
  {
    id: '1',
    name: 'PLC Unit 1',
    ip: '192.168.1.100',
    type: 'Siemens S7-1200',
    connected: true
  },
  {
    id: '2',
    name: 'PLC Unit 2',
    ip: '192.168.1.101',
    type: 'Allen Bradley',
    connected: true
  }
])

const sensors = ref<Sensor[]>([
  {
    id: '1',
    name: 'Temperature Sensor',
    location: 'Room A1',
    description: 'Main room temperature monitoring',
    plcId: '1',
    connectionType: 'AI',
    address: 'IW0',
    unit: '°C',
    status: 'online',
    currentValue: 23.5,
    minValue: -10,
    maxValue: 50,
    decimalPlaces: 1,
    lastUpdate: new Date()
  },
  {
    id: '2',
    name: 'Main Pump',
    location: 'Pump Room',
    plcId: '1',
    connectionType: 'DO',
    address: 'Q0.0',
    unit: '',
    status: 'online',
    outputState: true,
    lastUpdate: new Date()
  },
  {
    id: '3',
    name: 'Pressure Sensor',
    location: 'Tank B2',
    plcId: '2',
    connectionType: 'AI',
    address: 'IW2',
    unit: 'bar',
    status: 'online',
    currentValue: 15.2,
    minValue: 0,
    maxValue: 25,
    decimalPlaces: 1,
    lastUpdate: new Date()
  },
  {
    id: '4',
    name: 'Emergency Stop',
    location: 'Control Panel',
    plcId: '1',
    connectionType: 'DI',
    address: 'I0.0',
    unit: '',
    status: 'online',
    currentValue: 0,
    lastUpdate: new Date()
  }
])

const timeRanges = [
  { label: '1H', value: '1h' },
  { label: '24H', value: '24h' },
  { label: '7D', value: '7d' },
  { label: '30D', value: '30d' }
]

const analyticsData = ref({
  average: 23.1,
  min: 18.5,
  max: 28.3,
  uptime: 99.2,
  dataPoints: 1440,
  missingData: 0.8,
  totalAlerts: 5,
  highAlerts: 1,
  lastAlert: '2 hours ago'
})

// Computed
const filteredSensors = computed(() => {
  return sensors.value.filter(sensor => {
    const matchesSearch = sensor.name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
                         sensor.location.toLowerCase().includes(searchQuery.value.toLowerCase())
    const matchesStatus = !statusFilter.value || sensor.status === statusFilter.value
    const matchesConnection = !connectionFilter.value || sensor.connectionType === connectionFilter.value
    const matchesPLC = !plcFilter.value || sensor.plcId === plcFilter.value

    return matchesSearch && matchesStatus && matchesConnection && matchesPLC
  })
})

const counterSensors = computed(() => {
  return sensors.value.filter(sensor => 
    sensor.connectionType === 'AI' && sensor.unit && sensor.unit !== ''
  )
})

// Methods
const getStatusClass = (status: string) => {
  const classes = {
    online: 'status-online',
    offline: 'status-offline',
    warning: 'status-warning'
  }
  return `status-indicator ${classes[status as keyof typeof classes] || 'status-offline'}`
}

const getConnectionClass = (connectionType: string) => {
  const classes = {
    DI: 'connection-di',
    DO: 'connection-do',
    AI: 'connection-ai',
    AO: 'connection-ao'
  }
  return `connection-type-badge ${classes[connectionType as keyof typeof classes] || 'connection-di'}`
}

const getPLCName = (plcId: string) => {
  const plc = plcs.value.find(p => p.id === plcId)
  return plc ? plc.name : 'Unknown'
}

const formatTime = (date: Date) => {
  return date.toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

const closeModals = () => {
  showAddSensorModal.value = false
  showEditSensorModal.value = false
  resetCurrentSensor()
}

const resetCurrentSensor = () => {
  currentSensor.value = {
    name: '',
    location: '',
    description: '',
    plcId: '',
    connectionType: undefined,
    address: '',
    unit: '',
    minValue: 0,
    maxValue: 100,
    decimalPlaces: 2
  }
}

const resetConnectionFields = () => {
  if (currentSensor.value.connectionType === 'DI' || currentSensor.value.connectionType === 'DO') {
    currentSensor.value.minValue = undefined
    currentSensor.value.maxValue = undefined
    currentSensor.value.decimalPlaces = undefined
    currentSensor.value.unit = ''
  }
}

const editSensor = (sensor: Sensor) => {
  currentSensor.value = { ...sensor }
  showEditSensorModal.value = true
}

const saveSensor = () => {
  if (showEditSensorModal.value) {
    const index = sensors.value.findIndex(s => s.id === currentSensor.value.id)
    if (index !== -1) {
      sensors.value[index] = {
        ...currentSensor.value,
        lastUpdate: new Date()
      } as Sensor
    }
  } else {
    const newSensor: Sensor = {
      ...currentSensor.value,
      id: Date.now().toString(),
      status: 'offline',
      lastUpdate: new Date()
    } as Sensor
    sensors.value.push(newSensor)
  }
  closeModals()
}

const deleteSensor = (sensorId: string) => {
  if (confirm('Are you sure you want to delete this sensor?')) {
    const index = sensors.value.findIndex(s => s.id === sensorId)
    if (index !== -1) {
      sensors.value.splice(index, 1)
    }
  }
}

const toggleOutput = (sensorId: string, state: boolean) => {
  const sensor = sensors.value.find(s => s.id === sensorId)
  if (sensor && sensor.connectionType === 'DO') {
    sensor.outputState = state
    sensor.lastUpdate = new Date()
  }
}

const setAnalogOutput = (sensorId: string, value: number) => {
  const sensor = sensors.value.find(s => s.id === sensorId)
  if (sensor && sensor.connectionType === 'AO') {
    sensor.outputValue = value
    sensor.lastUpdate = new Date()
  }
}

const openControlModal = (sensor: Sensor) => {
  selectedSensor.value = sensor
  // Load existing control configuration
  controlConfig.value = {
    mode: 'manual',
    schedules: [],
    sensorRules: []
  }
  showControlModal.value = true
}

const openAnalytics = (sensor: Sensor) => {
  selectedSensor.value = sensor
  showAnalyticsModal.value = true
}

const addSchedule = () => {
  if (controlConfig.value.schedules.length < 5) {
    const newSchedule: Schedule = {
      id: Date.now().toString(),
      action: 'on',
      duration: 60,
      durationUnit: 'seconds',
      startTime: '12:00',
      repeat: false
    }
    controlConfig.value.schedules.push(newSchedule)
  }
}

const removeSchedule = (index: number) => {
  controlConfig.value.schedules.splice(index, 1)
}

const editSchedule = (index: number) => {
  // Implementation for editing schedule
  console.log('Edit schedule', index)
}

const addSensorRule = () => {
  const newRule: SensorRule = {
    id: Date.now().toString(),
    sensorId: '',
    condition: 'above',
    value: 0,
    action: 'turn_on'
  }
  controlConfig.value.sensorRules.push(newRule)
}

const removeSensorRule = (index: number) => {
  controlConfig.value.sensorRules.splice(index, 1)
}

const saveControlConfig = () => {
  // Save control configuration
  console.log('Saving control config:', controlConfig.value)
  showControlModal.value = false
}

const formatSchedule = (schedule: Schedule) => {
  let result = `${schedule.startTime}`
  if (schedule.date) {
    result += ` on ${schedule.date}`
  }
  if (schedule.repeat) {
    result += ` (${schedule.repeatType})`
  }
  return result
}

const getSensorName = (sensorId: string) => {
  const sensor = sensors.value.find(s => s.id === sensorId)
  return sensor ? sensor.name : 'Unknown Sensor'
}

const getSensorUnit = (sensorId: string) => {
  const sensor = sensors.value.find(s => s.id === sensorId)
  return sensor ? sensor.unit : ''
}

onMounted(() => {
  // Initialize data
})
</script>