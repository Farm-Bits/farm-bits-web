import { ref } from 'vue';
import { defineStore } from 'pinia';

export default defineStore('main', () => {
  const sidebarNarrow = ref(false);

  function toggleSidebar() {
    sidebarNarrow.value = !sidebarNarrow.value;
  }

  function updateSidebarNarrow(value: boolean) {
    sidebarNarrow.value = value;
  }

  return {
    sidebarNarrow,
    toggleSidebar,
    updateSidebarNarrow
  };
}, { persist: true });
