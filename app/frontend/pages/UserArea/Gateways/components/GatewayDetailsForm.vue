<template>
  <div class="flex-grow-1">
    <!-- Editable Name Input -->
    <div class="mb-2">
      <CFormLabel class="small fw-semibold mb-1">Display Name</CFormLabel>
      <CFormInput
        v-model="modelValue.customName"
        size="sm"
        placeholder="Enter Gateway name" />
    </div>

    <!-- Metadata -->
    <div class="metadata">
      <span class="metadata-item">
        <strong>Label:</strong> {{ gateway.label }}
      </span>
      <span class="metadata-item">
        <strong>IMEI:</strong> {{ gateway.imei }}
      </span>
      <span class="metadata-separator">•</span>
      <span class="metadata-item">
        <strong>ICCID:</strong> {{ gateway.iccid }}
      </span>
      <span class="metadata-separator">•</span>
      <span class="metadata-item">
        <strong>Phone:</strong> {{ gateway.phone_number || 'N/A' }}
      </span>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import type { Gateway } from '@/types/gateway';
  import type { Plc } from '@/types/plc';

  defineProps<{
    modelValue: {
      customName: string;
    };
    gateway: Gateway;
    availablePlcs: Plc[];
  }>();
</script>

<style scoped>
  .metadata {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 0.813rem;
    color: #6b7280;
  }

  .metadata-item strong {
    color: #374151;
    font-weight: 600;
  }

  .metadata-separator {
    color: #d1d5db;
  }
</style>
