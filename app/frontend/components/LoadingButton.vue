<template>
  <button
    :disabled="loading || disabled"
    :class="buttonClasses"
    @click="handleClick">
    <svg v-if="loading" class="loading-spinner" viewBox="0 0 24 24">
      <circle
        cx="12"
        cy="12"
        r="10"
        stroke="currentColor"
        stroke-width="4"
        fill="none"
        opacity="0.25" />
      <path
        fill="currentColor"
        opacity="0.75"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
    </svg>
    <slot></slot>
  </button>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';

  const props = withDefaults(
    defineProps<{
      loading?: boolean;
      disabled?: boolean;
    }>(), {
      loading: false,
      disabled: false
    }
  );

  const emit = defineEmits<{
    click: [event: MouseEvent]
  }>()

  const buttonClasses = computed(() => [
    'loading-button',
    { 'loading-button--loading': props.loading }
  ]);

  function handleClick(event: MouseEvent) {
    if (!props.loading && !props.disabled)
      emit('click', event);
  }
</script>

<style scoped>
  .loading-button:disabled {
    opacity: 0.6;
    cursor: not-allowed;
    pointer-events: none;
  }

  .loading-button--loading {
    pointer-events: none;
  }

  .loading-spinner {
    display: inline-block;
    width: 1rem;
    height: 1rem;
    animation: spin 1s linear infinite;
    flex-shrink: 0;
  }

  @keyframes spin {
    from {
      transform: rotate(0deg);
    }
    to {
      transform: rotate(360deg);
    }
  }

  .loading-button--loading .loading-spinner {
    margin-right: 0.5rem;
  }

  .loading-button--loading .loading-spinner:only-child {
    margin-right: 0;
  }
</style>
