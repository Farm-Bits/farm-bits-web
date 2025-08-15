import { ref } from 'vue';
import { defineStore } from 'pinia';

interface Toast {
  type: string;
  title: string;
  message: string;
};

export default defineStore('toast', () => {
  const toasts = ref<Toast[]>([]);

  function addToast(type: string, title: string, message: string) {
    toasts.value.push({ type, title, message });
  }

  return {
    toasts,
    addToast
  };
});
