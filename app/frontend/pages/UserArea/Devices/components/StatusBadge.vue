<template>
  <span class="status-cell">
    <span class="status-dot" :class="dotClass" />
    <span class="status-text" :class="textClass">{{ statusText }}</span>
  </span>
</template>

<script lang="ts" setup>
  import { computed, toRef } from 'vue';
  import useRelativeTime from '@/composables/useRelativeTime';
  import type { DeviceRow } from '../types';

  const props = defineProps<{ row: DeviceRow }>();

  const lastSeenSource = toRef(props.row, 'last_seen_at');
  const relativeTime = useRelativeTime(lastSeenSource);

  const statusText = computed(() => {
    switch (props.row.status) {
      case 'online':         return `Online · ${relativeTime.value}`;
      case 'offline':        return props.row.last_seen_at ? `Offline · ${relativeTime.value}` : 'Offline · never seen';
      case 'awaiting_setup': return 'Awaiting setup';
      case 'disabled':       return 'Disabled';
    }
  });

  const dotClass = computed(() => {
    return {
      'dot-online':   props.row.status === 'online',
      'dot-offline':  props.row.status === 'offline',
      'dot-awaiting': props.row.status === 'awaiting_setup',
      'dot-disabled': props.row.status === 'disabled',
    };
  });

  const textClass = computed(() => {
    return {
      'text-warning':   props.row.status === 'offline',
      'text-muted':     props.row.status === 'awaiting_setup' || props.row.status === 'disabled',
    };
  });
</script>

<style scoped>
  .status-cell {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    font-size: 0.9rem;
  }
  .status-dot {
    display: inline-block;
    width: 8px;
    height: 8px;
    border-radius: 50%;
    flex: none;
  }
  .dot-online   { background-color: var(--cui-success, #198754); }
  .dot-offline  { background-color: var(--cui-warning, #ffc107); }
  .dot-awaiting { background-color: var(--cui-secondary, #6c757d); }
  .dot-disabled { background-color: var(--cui-secondary, #6c757d); }
</style>
