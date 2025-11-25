<template>
  <div class="min-h-screen bg-gradient-to-br from-green-50 via-blue-50 to-purple-50">
    <!-- Navigation Header -->
    <nav class="bg-white shadow-lg border-b border-gray-200">
      <div class="max-w-7xl mx-auto px-6 py-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <div class="bg-gradient-to-r from-green-500 to-blue-500 p-2 rounded-xl">
              <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path>
              </svg>
            </div>
            <div>
              <h1 class="text-2xl font-bold text-gray-800">AgriProtocol</h1>
              <p class="text-sm text-gray-600">Smart Agricultural Management System</p>
            </div>
          </div>
          
          <div class="flex items-center space-x-4">
            <div class="flex items-center space-x-2 bg-gray-100 rounded-full px-4 py-2">
              <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
              <span class="text-sm font-medium text-gray-700">System Online</span>
            </div>
            
            <button class="p-2 text-gray-600 hover:bg-gray-100 rounded-full transition-colors" title="Notifications">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-5 5v-5zM15 17h5l-5 5v-5zM12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
            </button>
            
            <button class="p-2 text-gray-600 hover:bg-gray-100 rounded-full transition-colors" title="Profile">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
              </svg>
            </button>
          </div>
        </div>
      </div>
    </nav>

    <!-- Main Content -->
    <div class="max-w-7xl mx-auto p-6">
      <!-- Welcome Section -->
      <div class="mb-8">
        <h2 class="text-3xl font-bold text-gray-800 mb-2">Welcome back!</h2>
        <p class="text-gray-600">Here's what's happening with your protocols today.</p>
      </div>

      <!-- Dashboard Stats -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100 hover:shadow-xl transition-shadow duration-300">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-gray-600 mb-1">Total Protocols</p>
              <p class="text-3xl font-bold text-gray-800">{{ totalProtocols }}</p>
            </div>
            <div class="bg-gradient-to-r from-blue-100 to-blue-200 p-3 rounded-full">
              <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
              </svg>
            </div>
          </div>
          <div class="mt-4 flex items-center text-sm">
            <span class="text-green-600 flex items-center font-medium">
              <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18"></path>
              </svg>
              +12%
            </span>
            <span class="text-gray-600 ml-2">from last month</span>
          </div>
        </div>

        <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100 hover:shadow-xl transition-shadow duration-300">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-gray-600 mb-1">Active Protocols</p>
              <p class="text-3xl font-bold text-green-600">{{ activeProtocols }}</p>
            </div>
            <div class="bg-gradient-to-r from-green-100 to-green-200 p-3 rounded-full">
              <svg class="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
            </div>
          </div>
          <div class="mt-4 flex items-center text-sm">
            <span class="text-green-600 flex items-center font-medium">
              <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18"></path>
              </svg>
              +5%
            </span>
            <span class="text-gray-600 ml-2">this week</span>
          </div>
        </div>

        <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100 hover:shadow-xl transition-shadow duration-300">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-gray-600 mb-1">Crop Types</p>
              <p class="text-3xl font-bold text-purple-600">{{ totalCropTypes }}</p>
            </div>
            <div class="bg-gradient-to-r from-purple-100 to-purple-200 p-3 rounded-full">
              <svg class="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
              </svg>
            </div>
          </div>
          <div class="mt-4 flex items-center text-sm">
            <span class="text-blue-600 flex items-center font-medium">
              <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path>
              </svg>
              Stable
            </span>
            <span class="text-gray-600 ml-2">all systems</span>
          </div>
        </div>

        <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100 hover:shadow-xl transition-shadow duration-300">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-gray-600 mb-1">Avg Days/Protocol</p>
              <p class="text-3xl font-bold text-orange-600">{{ averageDaysPerProtocol }}</p>
            </div>
            <div class="bg-gradient-to-r from-orange-100 to-orange-200 p-3 rounded-full">
              <svg class="w-6 h-6 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
              </svg>
            </div>
          </div>
          <div class="mt-4 flex items-center text-sm">
            <span class="text-orange-600 flex items-center font-medium">
              <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
              </svg>
              Optimized
            </span>
            <span class="text-gray-600 ml-2">efficiency</span>
          </div>
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="bg-white rounded-2xl shadow-lg p-8 mb-8 border border-gray-100">
        <h2 class="text-xl font-bold text-gray-800 mb-6 flex items-center">
          <svg class="w-6 h-6 mr-2 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
          </svg>
          Quick Actions
        </h2>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <button
            @click="navigateToProtocols('create')"
            class="group bg-gradient-to-r from-green-500 to-green-600 text-white p-6 rounded-xl hover:from-green-600 hover:to-green-700 transform hover:scale-105 transition-all duration-200 shadow-lg hover:shadow-xl"
          >
            <div class="flex items-center space-x-4">
              <div class="bg-white bg-opacity-20 p-2 rounded-full group-hover:bg-opacity-30 transition-all">
                <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                </svg>
              </div>
              <div class="text-left">
                <h3 class="font-semibold text-lg">Create Protocol</h3>
                <p class="text-green-100 text-sm">Start a new growing protocol</p>
              </div>
            </div>
          </button>

          <button
            @click="navigateToProtocols('manage')"
            class="group bg-gradient-to-r from-blue-500 to-blue-600 text-white p-6 rounded-xl hover:from-blue-600 hover:to-blue-700 transform hover:scale-105 transition-all duration-200 shadow-lg hover:shadow-xl"
          >
            <div class="flex items-center space-x-4">
              <div class="bg-white bg-opacity-20 p-2 rounded-full group-hover:bg-opacity-30 transition-all">
                <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                </svg>
              </div>
              <div class="text-left">
                <h3 class="font-semibold text-lg">Manage Protocols</h3>
                <p class="text-blue-100 text-sm">View and edit existing protocols</p>
              </div>
            </div>
          </button>

          <button
            @click="showAnalytics = true"
            class="group bg-gradient-to-r from-purple-500 to-purple-600 text-white p-6 rounded-xl hover:from-purple-600 hover:to-purple-700 transform hover:scale-105 transition-all duration-200 shadow-lg hover:shadow-xl"
          >
            <div class="flex items-center space-x-4">
              <div class="bg-white bg-opacity-20 p-2 rounded-full group-hover:bg-opacity-30 transition-all">
                <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
                </svg>
              </div>
              <div class="text-left">
                <h3 class="font-semibold text-lg">Analytics</h3>
                <p class="text-purple-100 text-sm">View protocol performance</p>
              </div>
            </div>
          </button>
        </div>
      </div>

      <!-- Recent Activity -->
      <div class="bg-white rounded-2xl shadow-lg p-8 mb-8 border border-gray-100">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-xl font-bold text-gray-800 flex items-center">
            <svg class="w-6 h-6 mr-2 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            Recent Activity
          </h2>
          <button class="text-blue-600 hover:text-blue-700 font-medium text-sm hover:underline transition-all">
            View All
          </button>
        </div>
        
        <div class="space-y-4">
          <div class="flex items-center space-x-4 p-4 bg-gradient-to-r from-green-50 to-emerald-50 rounded-lg border border-green-200 hover:shadow-md transition-shadow">
            <div class="bg-green-500 p-2 rounded-full shadow-lg">
              <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
              </svg>
            </div>
            <div class="flex-1">
              <p class="font-medium text-gray-800">New protocol created: "Tomato Summer Protocol"</p>
              <p class="text-sm text-gray-600 flex items-center mt-1">
                <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                2 minutes ago
              </p>
            </div>
            <div class="text-green-600 font-semibold">New</div>
          </div>

          <div class="flex items-center space-x-4 p-4 bg-gradient-to-r from-blue-50 to-cyan-50 rounded-lg border border-blue-200 hover:shadow-md transition-shadow">
            <div class="bg-blue-500 p-2 rounded-full shadow-lg">
              <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
              </svg>
            </div>
            <div class="flex-1">
              <p class="font-medium text-gray-800">Protocol updated: "Lettuce Quick Grow"</p>
              <p class="text-sm text-gray-600 flex items-center mt-1">
                <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                15 minutes ago
              </p>
            </div>
            <div class="text-blue-600 font-semibold">Updated</div>
          </div>

          <div class="flex items-center space-x-4 p-4 bg-gradient-to-r from-orange-50 to-amber-50 rounded-lg border border-orange-200 hover:shadow-md transition-shadow">
            <div class="bg-orange-500 p-2 rounded-full shadow-lg">
              <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
            </div>
            <div class="flex-1">
              <p class="font-medium text-gray-800">Protocol activated: "Pepper Winter Protocol"</p>
              <p class="text-sm text-gray-600 flex items-center mt-1">
                <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                1 hour ago
              </p>
            </div>
            <div class="text-orange-600 font-semibold">Activated</div>
          </div>

          <div class="flex items-center space-x-4 p-4 bg-gradient-to-r from-red-50 to-pink-50 rounded-lg border border-red-200 hover:shadow-md transition-shadow">
            <div class="bg-red-500 p-2 rounded-full shadow-lg">
              <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
              </svg>
            </div>
            <div class="flex-1">
              <p class="font-medium text-gray-800">Protocol deleted: "Old Test Protocol"</p>
              <p class="text-sm text-gray-600 flex items-center mt-1">
                <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                3 hours ago
              </p>
            </div>
            <div class="text-red-600 font-semibold">Deleted</div>
          </div>
        </div>
      </div>

      <!-- Popular Protocols -->
      <div class="bg-white rounded-2xl shadow-lg p-8 border border-gray-100 mb-8">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-xl font-bold text-gray-800 flex items-center">
            <svg class="w-6 h-6 mr-2 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z"></path>
            </svg>
            Popular Protocols
          </h2>
          <button 
            @click="navigateToProtocols('manage')"
            class="text-blue-600 hover:text-blue-700 font-medium text-sm hover:underline transition-all"
          >
            View All Protocols
          </button>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div v-for="protocol in popularProtocols" :key="protocol.id" 
               class="group bg-gradient-to-br from-gray-50 to-blue-50 rounded-xl p-6 border border-gray-200 hover:shadow-lg hover:border-blue-300 transition-all duration-300 cursor-pointer"
               @click="viewProtocol(protocol)">
            <div class="flex items-center justify-between mb-4">
              <div class="flex items-center space-x-2">
                <div class="w-3 h-3 rounded-full" :class="protocol.active ? 'bg-green-500 animate-pulse' : 'bg-red-500'"></div>
                <span class="text-sm font-medium" :class="protocol.active ? 'text-green-700' : 'text-red-700'">
                  {{ protocol.active ? 'Active' : 'Inactive' }}
                </span>
              </div>
              <span class="bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-xs font-medium group-hover:bg-blue-200 transition-colors">
                {{ getCropTypeName(protocol.crop_type_id) }}
              </span>
            </div>
            
            <h3 class="font-semibold text-gray-800 mb-2 group-hover:text-blue-700 transition-colors">
              {{ protocol.name }}
            </h3>
            <p class="text-sm text-gray-600 mb-3 flex items-center">
              <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
              </svg>
              {{ protocol.protocol_days?.length || 0 }} days configured
            </p>
            
            <div class="flex items-center justify-between text-xs text-gray-500">
              <span class="flex items-center">
                <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"></path>
                </svg>
                {{ protocol.protocol_type }}
              </span>
              <span class="flex items-center">
                <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                {{ formatDate(protocol.updated_at) }}
              </span>
            </div>

            <!-- Progress Bar -->
            <div class="mt-4 pt-3 border-t border-gray-200">
              <div class="flex items-center justify-between mb-2">
                <span class="text-xs text-gray-600">Completion</span>
                <span class="text-xs font-medium text-gray-800">{{ getProtocolCompletionPercentage(protocol) }}%</span>
              </div>
              <div class="w-full bg-gray-200 rounded-full h-2">
                <div 
                  class="bg-gradient-to-r from-blue-500 to-purple-500 h-2 rounded-full transition-all duration-300"
                  :style="`width: ${getProtocolCompletionPercentage(protocol)}%`"
                ></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- System Status -->
      <div class="bg-white rounded-2xl shadow-lg p-8 border border-gray-100">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-xl font-bold text-gray-800 flex items-center">
            <svg class="w-6 h-6 mr-2 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            System Status
          </h2>
          <div class="flex items-center space-x-2">
            <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
            <span class="text-sm font-medium text-green-700">All Systems Operational</span>
          </div>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div class="bg-gradient-to-r from-green-50 to-emerald-50 rounded-lg p-4 border border-green-200">
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium text-gray-700">Protocol Engine</span>
              <span class="text-xs bg-green-100 text-green-800 px-2 py-1 rounded-full">Healthy</span>
            </div>
            <div class="flex items-center">
              <div class="w-full bg-green-200 rounded-full h-2 mr-3">
                <div class="bg-green-500 h-2 rounded-full" style="width: 98%"></div>
              </div>
              <span class="text-sm font-semibold text-green-700">98%</span>
            </div>
          </div>
          
          <div class="bg-gradient-to-r from-blue-50 to-cyan-50 rounded-lg p-4 border border-blue-200">
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium text-gray-700">Database</span>
              <span class="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded-full">Online</span>
            </div>
            <div class="flex items-center">
              <div class="w-full bg-blue-200 rounded-full h-2 mr-3">
                <div class="bg-blue-500 h-2 rounded-full" style="width: 100%"></div>
              </div>
              <span class="text-sm font-semibold text-blue-700">100%</span>
            </div>
          </div>
          
          <div class="bg-gradient-to-r from-purple-50 to-indigo-50 rounded-lg p-4 border border-purple-200">
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium text-gray-700">API Services</span>
              <span class="text-xs bg-purple-100 text-purple-800 px-2 py-1 rounded-full">Active</span>
            </div>
            <div class="flex items-center">
              <div class="w-full bg-purple-200 rounded-full h-2 mr-3">
                <div class="bg-purple-500 h-2 rounded-full" style="width: 95%"></div>
              </div>
              <span class="text-sm font-semibold text-purple-700">95%</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Analytics Modal -->
    <div v-if="showAnalytics" class="fixed inset-0 z-50 overflow-y-auto">
      <div class="fixed inset-0 bg-black bg-opacity-50 transition-opacity" @click="showAnalytics = false"></div>
      <div class="flex min-h-full items-center justify-center p-4">
        <div class="relative w-full max-w-6xl bg-white rounded-2xl shadow-2xl transform transition-all max-h-[90vh] overflow-hidden">
          <!-- Modal Header -->
          <div class="bg-gradient-to-r from-purple-500 to-blue-500 px-8 py-6">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-3">
                <div class="bg-white bg-opacity-20 p-2 rounded-full">
                  <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
                  </svg>
                </div>
                <div>
                  <h2 class="text-2xl font-bold text-white">Protocol Analytics</h2>
                  <p class="text-blue-100 text-sm">Performance insights and trends</p>
                </div>
              </div>
              <button 
                @click="showAnalytics = false" 
                class="text-white hover:bg-white hover:bg-opacity-20 p-2 rounded-full transition-colors"
              >
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>
          </div>
          
          <!-- Modal Content -->
          <div class="p-8 overflow-y-auto max-h-[calc(90vh-120px)]">
            <!-- Key Metrics -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
              <div class="bg-gradient-to-r from-green-50 to-emerald-50 rounded-lg p-6 text-center border border-green-200">
                <div class="text-3xl font-bold text-green-600 mb-2">{{ successRate }}%</div>
                <div class="text-sm text-gray-600">Success Rate</div>
              </div>
              
              <div class="bg-gradient-to-r from-blue-50 to-cyan-50 rounded-lg p-6 text-center border border-blue-200">
                <div class="text-3xl font-bold text-blue-600 mb-2">{{ avgGrowthTime }}</div>
                <div class="text-sm text-gray-600">Avg Growth Time</div>
              </div>
              
              <div class="bg-gradient-to-r from-purple-50 to-indigo-50 rounded-lg p-6 text-center border border-purple-200">
                <div class="text-3xl font-bold text-purple-600 mb-2">{{ totalYield }}</div>
                <div class="text-sm text-gray-600">Total Yield (kg)</div>
              </div>
              
              <div class="bg-gradient-to-r from-orange-50 to-amber-50 rounded-lg p-6 text-center border border-orange-200">
                <div class="text-3xl font-bold text-orange-600 mb-2">{{ efficiencyScore }}</div>
                <div class="text-sm text-gray-600">Efficiency Score</div>
              </div>
            </div>

            <!-- Charts Section -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
              <!-- Protocol Distribution -->
              <div class="bg-gradient-to-r from-green-50 to-emerald-50 rounded-xl p-6 border border-green-200">
                <h3 class="font-semibold text-gray-800 mb-6 flex items-center">
                  <svg class="w-5 h-5 mr-2 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
                  </svg>
                  Protocol Status Distribution
                </h3>
                <div class="space-y-4">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-3">
                      <div class="w-4 h-4 bg-green-500 rounded-full"></div>
                      <span class="text-sm text-gray-700">Active Protocols</span>
                    </div>
                    <div class="flex items-center space-x-3">
                      <div class="w-32 bg-gray-200 rounded-full h-3">
                        <div class="bg-green-500 h-3 rounded-full transition-all duration-500" :style="`width: ${(activeProtocols/totalProtocols)*100}%`"></div>
                      </div>
                      <span class="text-sm font-medium text-gray-800 w-8">{{ activeProtocols }}</span>
                    </div>
                  </div>
                  
                  <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-3">
                      <div class="w-4 h-4 bg-red-500 rounded-full"></div>
                      <span class="text-sm text-gray-700">Inactive Protocols</span>
                    </div>
                    <div class="flex items-center space-x-3">
                      <div class="w-32 bg-gray-200 rounded-full h-3">
                        <div class="bg-red-500 h-3 rounded-full transition-all duration-500" :style="`width: ${((totalProtocols-activeProtocols)/totalProtocols)*100}%`"></div>
                      </div>
                      <span class="text-sm font-medium text-gray-800 w-8">{{ totalProtocols - activeProtocols }}</span>
                    </div>
                  </div>
                </div>
              </div>
              
              <!-- Crop Type Distribution -->
              <div class="bg-gradient-to-r from-blue-50 to-cyan-50 rounded-xl p-6 border border-blue-200">
                <h3 class="font-semibold text-gray-800 mb-6 flex items-center">
                  <svg class="w-5 h-5 mr-2 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
                  </svg>
                  Crop Type Distribution
                </h3>
                <div class="space-y-3">
                  <div v-for="(cropType, index) in cropTypeStats" :key="cropType.name" class="flex items-center justify-between">
                    <div class="flex items-center space-x-3">
                      <div 
                        class="w-4 h-4 rounded-full"
                        :class="getCropTypeColor(index)"
                      ></div>
                      <span class="text-sm text-gray-700">{{ cropType.name }}</span>
                    </div>
                    <div class="flex items-center space-x-3">
                      <div class="w-24 bg-gray-200 rounded-full h-2">
                        <div 
                          :class="getCropTypeBarColor(index)"
                          class="h-2 rounded-full transition-all duration-500" 
                          :style="`width: ${Math.max((cropType.count/totalProtocols)*100, 5)}%`"
                        ></div>
                      </div>
                      <span class="text-sm font-medium text-gray-800 w-6">{{ cropType.count }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Performance Trends -->
            <div class="bg-gradient-to-r from-purple-50 to-indigo-50 rounded-xl p-6 border border-purple-200">
              <h3 class="font-semibold text-gray-800 mb-6 flex items-center">
                <svg class="w-5 h-5 mr-2 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path>
                </svg>
                Performance Trends
              </h3>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div class="bg-white rounded-lg p-4 border border-purple-200">
                  <div class="text-lg font-semibold text-gray-800 mb-1">Protocol Efficiency</div>
                  <div class="text-3xl font-bold text-purple-600">94%</div>
                  <div class="text-sm text-green-600 flex items-center mt-2">
                    <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18"></path>
                    </svg>
                    +3% this month
                  </div>
                </div>
                
                <div class="bg-white rounded-lg p-4 border border-purple-200">
                  <div class="text-lg font-semibold text-gray-800 mb-1">Resource Usage</div>
                  <div class="text-3xl font-bold text-blue-600">87%</div>
                  <div class="text-sm text-orange-600 flex items-center mt-2">
                    <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 17h8m0 0V9m0 8l-8-8-4 4-6-6"></path>
                    </svg>
                    Stable
                  </div>
                </div>
                
                <div class="bg-white rounded-lg p-4 border border-purple-200">
                  <div class="text-lg font-semibold text-gray-800 mb-1">Automation Level</div>
                  <div class="text-3xl font-bold text-green-600">91%</div>
                  <div class="text-sm text-green-600 flex items-center mt-2">
                    <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18"></path>
                    </svg>
                    +7% this month
                  </div>
                </div>
              </div>
            </div>

            <!-- Action Items -->
            <div class="mt-8 bg-gradient-to-r from-yellow-50 to-orange-50 rounded-xl p-6 border border-yellow-200">
              <h3 class="font-semibold text-gray-800 mb-4 flex items-center">
                <svg class="w-5 h-5 mr-2 text-yellow-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.664-.833-2.464 0L3.34 16.5c-.77.833.192 2.5 1.732 2.5z"></path>
                </svg>
                Recommendations
              </h3>
              <div class="space-y-3">
                <div class="flex items-start space-x-3 p-3 bg-white rounded-lg border border-yellow-200">
                  <div class="bg-blue-100 p-1 rounded-full mt-1">
                    <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                  </div>
                  <div>
                    <div class="font-medium text-gray-800">Optimize temperature settings</div>
                    <div class="text-sm text-gray-600">Consider adjusting day/night temperature differentials in tomato protocols for better yield.</div>
                  </div>
                </div>
                
                <div class="flex items-start space-x-3 p-3 bg-white rounded-lg border border-yellow-200">
                  <div class="bg-green-100 p-1 rounded-full mt-1">
                    <svg class="w-4 h-4 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                  </div>
                  <div>
                    <div class="font-medium text-gray-800">Update inactive protocols</div>
                    <div class="text-sm text-gray-600">Review and activate {{ totalProtocols - activeProtocols }} inactive protocols or archive if no longer needed.</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Modal Footer -->
          <div class="bg-gray-50 px-8 py-4 flex items-center justify-between border-t">
            <div class="text-sm text-gray-600">
              Last updated: {{ getCurrentTimestamp() }}
            </div>
            <button
              @click="showAnalytics = false"
              class="px-6 py-2 bg-gradient-to-r from-purple-500 to-blue-500 text-white rounded-lg font-semibold hover:from-purple-600 hover:to-blue-600 transition-all duration-200"
            >
              Close Analytics
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

// Reactive data
const showAnalytics = ref(false)
const protocols = ref([])
const cropTypes = ref([])

// Analytics mock data
const successRate = ref(92)
const avgGrowthTime = ref('45d')
const totalYield = ref('2.4k')
const efficiencyScore = ref('A+')

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

  // Mock protocols data
  protocols.value = [
    {
      id: 1,
      name: 'Tomato Summer Protocol',
      protocol_type: 'Standard',
      crop_type_id: 1,
      active: true,
      updated_at: '2024-08-20T14:30:00Z',
      protocol_days: [
        { day_number: 1, temperature_day: 24, humidity_day: 65 },
        { day_number: 2, temperature_day: 25, humidity_day: 70 }
      ]
    },
    {
      id: 2,
      name: 'Lettuce Quick Grow',
      protocol_type: 'Express',
      crop_type_id: 2,
      active: true,
      updated_at: '2024-08-15T16:45:00Z',
      protocol_days: [
        { day_number: 1, temperature_day: 20 }
      ]
    },
    {
      id: 3,
      name: 'Pepper Winter Protocol',
      protocol_type: 'Specialized',
      crop_type_id: 3,
      active: false,
      updated_at: '2024-07-30T11:15:00Z',
      protocol_days: []
    },
    {
      id: 4,
      name: 'Herb Garden Mix',
      protocol_type: 'Standard',
      crop_type_id: 4,
      active: true,
      updated_at: '2024-08-10T09:20:00Z',
      protocol_days: [
        { day_number: 1 },
        { day_number: 2 },
        { day_number: 3 }
      ]
    },
    {
      id: 5,
      name: 'Strawberry Seasonal',
      protocol_type: 'Seasonal',
      crop_type_id: 5,
      active: true,
      updated_at: '2024-08-05T12:30:00Z',
      protocol_days: [
        { day_number: 1 },
        { day_number: 2 }
      ]
    }
  ]
})

// Computed properties
const totalProtocols = computed(() => protocols.value.length)
const activeProtocols = computed(() => protocols.value.filter(p => p.active).length)
const totalCropTypes = computed(() => cropTypes.value.length)
const averageDaysPerProtocol = computed(() => {
  if (protocols.value.length === 0) return 0
  const totalDays = protocols.value.reduce((sum, p) => sum + (p.protocol_days?.length || 0), 0)
  return Math.round(totalDays / protocols.value.length * 10) / 10
})

const popularProtocols = computed(() => {
  return protocols.value
    .sort((a, b) => (b.protocol_days?.length || 0) - (a.protocol_days?.length || 0))
    .slice(0, 6)
})

const cropTypeStats = computed(() => {
  const stats = {}
  protocols.value.forEach(protocol => {
    const cropType = getCropTypeName(protocol.crop_type_id)
    stats[cropType] = (stats[cropType] || 0) + 1
  })
  
  return Object.entries(stats)
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count)
})

// Methods
const getCropTypeName = (cropTypeId) => {
  const cropType = cropTypes.value.find(ct => ct.id === cropTypeId)
  return cropType ? cropType.name : 'Unknown'
}

const formatDate = (dateString) => {
  if (!dateString) return 'N/A'
  return new Date(dateString).toLocaleDateString('en-US', { 
    month: 'short', 
    day: 'numeric'
  })
}

const getCurrentTimestamp = () => {
  return new Date().toLocaleString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const getProtocolCompletionPercentage = (protocol) => {
  // Mock completion calculation based on configured parameters
  const daysCount = protocol.protocol_days?.length || 0
  if (daysCount === 0) return 0
  
  // Calculate based on average parameter completion
  const maxParams = 15 // Max parameters per day
  let totalConfigured = 0
  
  protocol.protocol_days.forEach(day => {
    let configured = 0
    if (day.temperature_day) configured++
    if (day.temperature_night) configured++
    if (day.humidity_day) configured++
    if (day.humidity_night) configured++
    if (day.co2_day) configured++
    // Add other parameters...
    totalConfigured += configured
  })
  
  return Math.min(Math.round((totalConfigured / (daysCount * maxParams)) * 100), 100)
}

const getCropTypeColor = (index) => {
  const colors = ['bg-blue-500', 'bg-green-500', 'bg-purple-500', 'bg-orange-500', 'bg-pink-500']
  return colors[index % colors.length]
}

const getCropTypeBarColor = (index) => {
  const colors = ['bg-blue-500', 'bg-green-500', 'bg-purple-500', 'bg-orange-500', 'bg-pink-500']
  return colors[index % colors.length]
}

const navigateToProtocols = (action) => {
  // In a real app, this would use Vue Router
  console.log('Navigate to protocols page with action:', action)
}

const viewProtocol = (protocol) => {
  // In a real app, this would navigate to protocol detail
  console.log('View protocol:', protocol.id)
}
</script>
