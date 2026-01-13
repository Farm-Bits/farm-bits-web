<template>
  <div class="text-muted small mt-1">
    {{ relativeTime }}
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';

  const props = defineProps<{
    dateTime: string | null;
  }>();

  const relativeTime = computed(() => {
    if (!props.dateTime)
      return '';

    const date = new Date(props.dateTime);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHour = Math.floor(diffMin / 60);
    const diffDay = Math.floor(diffHour / 24);

    if (diffSec < 60)
      return 'Just now';
    if (diffMin < 60)
      return `${diffMin}m ago`;
    if (diffHour < 24)
      return `${diffHour}h ago`;
    if (diffDay < 7)
      return `${diffDay}d ago`;

    return date.toLocaleDateString();
  });
</script>

<style scoped>
</style>
