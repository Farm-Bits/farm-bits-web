<template>
  <div>
    <div v-if="flash.errors" class="alert">
      <ul class="list-disc pl-5">
        <li v-for="(error, index) in flash.errors" :key="index">
          {{ error }}
        </li>
      </ul>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import { usePage } from '@inertiajs/vue3';

  const page = usePage<{
    flash: {
      errors?: string[];
    };
  }>();
  const flash = computed(() => page.props.flash);
</script>

<style scoped>
  .alert {
    background-color: #f8d7da;
    color: #721c24;
    border: 1px solid #f5c6cb;
    padding: 10px;
    border-radius: 4px;
    margin-bottom: 15px;
  }
</style>
