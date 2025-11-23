<template>
  <div class="min-h-screen bg-gradient-to-br from-green-50 to-blue-50 p-6">
    <div class="max-w-7xl mx-auto">
      <!-- Header Section -->
      <div class="bg-white rounded-2xl shadow-xl p-8 mb-8">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <div class="bg-gradient-to-r from-green-500 to-blue-500 p-3 rounded-full">
              <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
            </div>
            <div>
              <h1 class="text-4xl font-bold text-gray-800">Protocol Management</h1>
              <p class="text-gray-600 mt-1">Manage your agricultural protocols and growing conditions</p>
            </div>
          </div>
          <button 
            @click="showCreateModal = true"
            class="bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-white px-6 py-3 rounded-xl font-semibold shadow-lg hover:shadow-xl transform hover:scale-105 transition-all duration-200 flex items-center space-x-2"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
            </svg>
            <span>New Protocol</span>
          </button>
        </div>
      </div>

      <!-- Search and Filter Section -->
      <div class="bg-white rounded-2xl shadow-xl p-6 mb-8">
        <div class="flex flex-wrap gap-4 items-center">
          <div class="flex-1 min-w-72">
            <div class="relative">
              <svg class="absolute left-3 top-3 w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
              </svg>
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Search protocols..."
                class="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
              />
            </div>
          </div>
          <select
            v-model="filterCropType"
            class="px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
          >
            <option value="">All Crop Types</option>
            <option v-for="cropType in cropTypes" :key="cropType.id" :value="cropType.id">
              {{ cropType.name }}
            </option>
          </select>
          <select
            v-model="filterActive"
            class="px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
          >
            <option value="">All Status</option>
            <option value="true">Active</option>
            <option value="false">Inactive</option>
          </select>
        </div>
      </div>

      <!-- Protocols Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          v-for="protocol in filteredProtocols"
          :key="protocol.id"
          class="bg-white rounded-2xl shadow-lg hover:shadow-xl transform hover:scale-105 transition-all duration-300 overflow-hidden border border-gray-100"
        >
          <div class="p-6">
            <div class="flex items-center justify-between mb-4">
              <div class="flex items-center space-x-2">
                <div class="w-3 h-3 rounded-full" :class="protocol.active ? 'bg-green-500' : 'bg-red-500'"></div>
                <span class="text-sm font-medium" :class="protocol.active ? 'text-green-700' : 'text-red-700'">
                  {{ protocol.active ? 'Active' : 'Inactive' }}
                </span>
              </div>
              <div class="flex space-x-2">
                <button
                  @click="viewProtocol(protocol)"
                  class="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                  title="View Protocol"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                  </svg>
                </button>
                <button
                  @click="editProtocol(protocol)"
                  class="p-2 text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                  title="Edit Protocol"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                  </svg>
                </button>
                <button
                  @click="deleteProtocol(protocol)"
                  class="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                  title="Delete Protocol"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                  </svg>
                </button>
              </div>
            </div>

            <h3 class="text-xl font-bold text-gray-800 mb-2">{{ protocol.name }}</h3>
            
            <div class="space-y-2 mb-4">
              <div class="flex items-center justify-between">
                <span class="text-sm text-gray-600">Type:</span>
                <span class="text-sm font-medium text-gray-800">{{ protocol.protocol_type || 'Standard' }}</span>
              </div>
              <div class="flex items-center justify-between">
                <span class="text-sm text-gray-600">Crop:</span>
                <span class="text-sm font-medium text-gray-800">{{ getCropTypeName(protocol.crop_type_id) }}</span>
              </div>
              <div class="flex items-center justify-between">
                <span class="text-sm text-gray-600">Days:</span>
                <span class="text-sm font-medium text-gray-800">{{ protocol.protocol_days?.length || 0 }} configured</span>
              </div>
            </div>

            <div class="flex items-center justify-between text-xs text-gray-500">
              <span>Created: {{ formatDate(protocol.created_at) }}</span>
              <span>Updated: {{ formatDate(protocol.updated_at) }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div v-if="filteredProtocols.length === 0" class="text-center py-16">
        <div class="bg-white rounded-2xl shadow-lg p-12 max-w-md mx-auto">
          <svg class="w-16 h-16 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
          </svg>
          <h3 class="text-lg font-semibold text-gray-800 mb-2">No protocols found</h3>
          <p class="text-gray-600 mb-4">Get started by creating your first protocol</p>
          <button 
            @click="showCreateModal = true"
            class="bg-gradient-to-r from-green-500 to-green-600 text-white px-6 py-2 rounded-xl font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200"
          >
            Create Protocol
          </button>
        </div>
      </div>
    </div>

    <!-- Create/Edit Modal -->
    <ProtocolModal
      :show="showCreateModal || showEditModal"
      :protocol="selectedProtocol"
      :crop-types="cropTypes"
      :is-editing="showEditModal"
      @close="closeModal"
      @save="saveProtocol"
    />

    <!-- View Modal -->
    <ProtocolViewModal
      :show="showViewModal"
      :protocol="selectedProtocol"
      :crop-types="cropTypes"
      @close="closeViewModal"
      @edit="editFromView"
    />
  </div>
</template>

<script setup>
  import { ref, computed, onMounted } from 'vue'
  import ProtocolModal from './ProtocolModal.vue'
  import ProtocolViewModal from './ProtocolViewModal.vue'

  // Reactive data
  const protocols = ref([])
  const cropTypes = ref([])
  const searchQuery = ref('')
  const filterCropType = ref('')
  const filterActive = ref('')
  const showCreateModal = ref(false)
  const showEditModal = ref(false)
  const showViewModal = ref(false)
  const selectedProtocol = ref(null)

  // Computed properties
  const filteredProtocols = computed(() => {
    return protocols.value.filter(protocol => {
      const matchesSearch = !searchQuery.value || 
        protocol.name.toLowerCase().includes(searchQuery.value.toLowerCase())
      
      const matchesCropType = !filterCropType.value || 
        protocol.crop_type_id === parseInt(filterCropType.value)
      
      const matchesActive = filterActive.value === '' || 
        protocol.active.toString() === filterActive.value
      
      return matchesSearch && matchesCropType && matchesActive
    })
  })

  // Methods
  const getCropTypeName = (cropTypeId) => {
    const cropType = cropTypes.value.find(ct => ct.id === cropTypeId)
    return cropType ? cropType.name : 'Unknown'
  }

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A'
    return new Date(dateString).toLocaleDateString()
  }

  const viewProtocol = (protocol) => {
    selectedProtocol.value = protocol
    showViewModal.value = true
  }

  const editProtocol = (protocol) => {
    selectedProtocol.value = { ...protocol }
    showEditModal.value = true
  }

  const editFromView = (protocol) => {
    showViewModal.value = false
    editProtocol(protocol)
  }

  const deleteProtocol = (protocol) => {
    if (confirm(`Are you sure you want to delete "${protocol.name}"?`)) {
      protocols.value = protocols.value.filter(p => p.id !== protocol.id)
      // Here you would make API call to delete
      console.log('Deleting protocol:', protocol.id)
    }
  }

  const closeModal = () => {
    showCreateModal.value = false
    showEditModal.value = false
    selectedProtocol.value = null
  }

  const closeViewModal = () => {
    showViewModal.value = false
    selectedProtocol.value = null
  }

  const saveProtocol = (protocolData) => {
    if (showEditModal.value) {
      // Update existing protocol
      const index = protocols.value.findIndex(p => p.id === protocolData.id)
      if (index !== -1) {
        protocols.value[index] = { ...protocolData, updated_at: new Date().toISOString() }
      }
    } else {
      // Create new protocol
      const newProtocol = {
        ...protocolData,
        id: Date.now(), // In real app, this would come from API
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }
      protocols.value.unshift(newProtocol)
    }
    closeModal()
  }

  // Mock data - replace with API calls
  onMounted(() => {
    // Mock crop types
    cropTypes.value = [
      { id: 1, name: 'Tomatoes' },
      { id: 2, name: 'Lettuce' },
      { id: 3, name: 'Peppers' },
      { id: 4, name: 'Herbs' },
      { id: 5, name: 'Strawberries' }
    ]

    // Mock protocols
    protocols.value = [
      {
        id: 1,
        name: 'Tomato Summer Protocol',
        protocol_type: 'Standard',
        protocol_subtype: 'Seasonal',
        crop_type_id: 1,
        active: true,
        client_id: 1,
        created_at: '2024-01-15T10:00:00Z',
        updated_at: '2024-08-20T14:30:00Z',
        protocol_days: [
          { day_number: 1, crop_stage_id: 1, temperature_day: 24, temperature_night: 18 },
          { day_number: 2, crop_stage_id: 1, temperature_day: 25, temperature_night: 19 }
        ]
      },
      {
        id: 2,
        name: 'Lettuce Quick Grow',
        protocol_type: 'Express',
        protocol_subtype: 'Fast Growth',
        crop_type_id: 2,
        active: true,
        client_id: 1,
        created_at: '2024-02-10T08:00:00Z',
        updated_at: '2024-08-15T16:45:00Z',
        protocol_days: [
          { day_number: 1, crop_stage_id: 1, temperature_day: 20, temperature_night: 16 }
        ]
      },
      {
        id: 3,
        name: 'Pepper Winter Protocol',
        protocol_type: 'Specialized',
        protocol_subtype: 'Climate Controlled',
        crop_type_id: 3,
        active: false,
        client_id: 1,
        created_at: '2024-03-05T12:00:00Z',
        updated_at: '2024-07-30T11:15:00Z',
        protocol_days: []
      }
    ]
  })
</script>
