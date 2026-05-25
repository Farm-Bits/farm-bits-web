<template>
  <div>
    <div v-if="page.props.errors && page.props.errors.length > 0" class="alert">
      <ul class="list-disc pl-5">
        <li v-for="(error, index) in page.props.errors" :key="index">
          {{ error }}
        </li>
      </ul>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { usePage } from '@inertiajs/vue3';

  const page = usePage<{
    errors?: string[];
  }>();
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
