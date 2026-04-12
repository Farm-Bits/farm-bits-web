import { ref } from 'vue';
import { defineStore } from 'pinia';

export default defineStore('main', () => {
  const sidebarNarrow = ref(false);
  const sidebarVisible = ref(true);

  function toggleSidebar() {
    sidebarNarrow.value = !sidebarNarrow.value;
  }

  function updateSidebarNarrow(value: boolean) {
    sidebarNarrow.value = value;
  }

  function toggleSidebarVisibility() {
    sidebarVisible.value = !sidebarVisible.value
  }

  function setSidebarVisible(value: boolean) {
    sidebarVisible.value = value
  }

  return {
    sidebarNarrow,
    sidebarVisible,
    toggleSidebar,
    updateSidebarNarrow,
    toggleSidebarVisibility,
    setSidebarVisible
  };
}, { persist: { pick: ['sidebarNarrow'] } });
