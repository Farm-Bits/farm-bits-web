import { ref } from 'vue';
import type { FlatDeviceRow } from '../types';

export type ModalKind = 'setup' | 'edit' | 'remove';

export default function useDeviceModals() {
  const setupOpen = ref(false);
  const editOpen = ref(false);
  const removeOpen = ref(false);

  const selectedRow = ref<FlatDeviceRow | null>(null);

  function openSetup(row: FlatDeviceRow) {
    selectedRow.value = row;
    setupOpen.value = true;
  }

  function openEdit(row: FlatDeviceRow) {
    selectedRow.value = row;
    editOpen.value = true;
  }

  function openRemove(row: FlatDeviceRow) {
    selectedRow.value = row;
    removeOpen.value = true;
  }

  function close() {
    setupOpen.value = false;
    editOpen.value = false;
    removeOpen.value = false;
    // Defer clearing selected row so modal close animation can render with
    // its content intact for one frame
    setTimeout(() => {
      selectedRow.value = null;
    }, 200);
  }

  return {
    setupOpen,
    editOpen,
    removeOpen,
    selectedRow,
    openSetup,
    openEdit,
    openRemove,
    close,
  };
}
