<template>
  <div>
    <div v-if="flash.alert" class="alert">
      {{ flash.alert }}
    </div>
    <div v-if="flash.notice" class="notice">
      {{ flash.notice }}
    </div>
    <div v-if="errors" class="alert">
      <ul class="list-disc pl-5">
        <li v-for="(error, index) in errors" :key="index">
          {{ error }}
        </li>
      </ul>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import { usePage } from '@inertiajs/vue3';

  type FlashType = 'alert' | 'notice' | string;
  interface FlashHash {
    [key: FlashType]: string | null | undefined;
    alert?: string;
    notice?: string;
  };
  interface PageProps {
    flash: FlashHash;
    errors?: string[];
    [key: string]: unknown;
  };

  const page = usePage<PageProps>();
  const flash = computed(() => page.props.flash);
  const errors = computed(() => page.props.errors);
</script>

<style scoped>
</style>
