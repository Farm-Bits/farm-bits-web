<template>
  <div class="w-full block">
    <div ref="triggerRef">
      <!-- Color Display Button -->
      <button
        variant="outline"
        @click="togglePicker"
        class="d-flex align-items-center justify-content-between w-100 text-start bg-transparent p-2"
        :class="{ 'border-danger': invalid }">

        <div class="d-flex align-items-center">
          <!-- Color Preview -->
          <div
            class="me-3 border rounded"
            style="width: 24px; height: 24px; border-width: 2px !important;"
            :style="{ backgroundColor: modelValue || '#ffffff' }">
          </div>

          <!-- Color Value Display -->
          <span :class="modelValue ? 'text-dark fw-medium' : 'text-muted'">
            {{ displayValue }}
          </span>
        </div>
      </button>
    </div>

    <!-- Color Picker Dropdown - Teleported to body -->
    <Teleport to="body">
      <CCard
        v-if="showPicker"
        class="color-picker-dropdown shadow-lg"
        :style="dropdownStyle"
        @click.stop>
        <CCardBody class="p-3">
          <!-- Preset Colors -->
          <div class="mb-3">
            <h6 class="mb-2">Preset Colors</h6>
            <div class="preset-colors-grid">
              <button
                v-for="preset in presetColors"
                :key="preset"
                type="button"
                @click="selectColor(preset)"
                class="preset-color-btn"
                :class="{
                  'selected': modelValue === preset
                }"
                :style="{ backgroundColor: preset }"
                :title="preset">
              </button>
            </div>
          </div>

          <!-- Actions -->
          <div class="d-flex justify-content-between align-items-center pt-2 border-top">
            <CButton color="secondary" @click="clearColor">
              Clear
            </CButton>
          </div>

        </CCardBody>
      </CCard>

      <!-- Click Outside Handler -->
      <div
        v-if="showPicker"
        @click="closePicker"
        class="color-picker-backdrop">
      </div>
    </Teleport>
  </div>
</template>

<script lang="ts" setup>
  import { computed, ref, onMounted, onUnmounted, nextTick } from 'vue';

  const props = defineProps<{
    modelValue: string | null;
    invalid?: boolean;
  }>();

  const presetColors = [
    '#dc3545', '#fd7e14', '#ffc107', '#198754', '#20c997', '#0dcaf0',
    '#0d6efd', '#6f42c1', '#d63384', '#6c757d', '#495057', '#343a40',
    '#f8f9fa', '#e9ecef', '#dee2e6', '#ced4da', '#adb5bd', '#6c757d',
    '#495057', '#343a40', '#212529', '#ffffff', '#000000', '#ff6b6b',
    '#4ecdc4', '#45b7d1', '#96ceb4', '#ffeaa7', '#dda0dd', '#98d8c8',
    '#f7dc6f', '#bb8fce', '#85c1e9', '#f8c471', '#82e0aa'
  ];

  const emit = defineEmits<{
    'update:modelValue': [value: string | null];
    'blur': [];
  }>();

  const showPicker = ref(false);
  const triggerRef = ref<HTMLElement>();
  const dropdownStyle = ref({});

  const displayValue = computed(() => {
    if (!props.modelValue)
      return 'Select a color';
    return props.modelValue.toUpperCase();
  });

  function togglePicker() {
    showPicker.value = !showPicker.value;
    if (showPicker.value)
      nextTick(() => {
        updateDropdownPosition();
      });
  }

  function updateDropdownPosition() {
    if (!triggerRef.value)
      return;

    const rect = triggerRef.value.getBoundingClientRect();
    const dropdownHeight = 400;
    const viewportHeight = window.innerHeight;
    const spaceBelow = viewportHeight - rect.bottom;
    const spaceAbove = rect.top;

    const showAbove = spaceBelow < dropdownHeight && spaceAbove > spaceBelow;

    dropdownStyle.value = {
      position: 'fixed',
      left: `${rect.left}px`,
      width: `${rect.width}px`,
      zIndex: 9999,
      top: showAbove ? `${rect.top - dropdownHeight}px` : `${rect.bottom + 4}px`,
      maxHeight: showAbove ? `${spaceAbove - 10}px` : `${spaceBelow - 10}px`
    };
  }

  function closePicker() {
    showPicker.value = false;
    emit('blur');
  }

  function selectColor(color: string) {
    emit('update:modelValue', color);
    closePicker();
  }

  function clearColor() {
    emit('update:modelValue', null);
    closePicker();
  }

  function handleEscape(event: KeyboardEvent) {
    if (event.key === 'Escape' && showPicker.value)
      closePicker();
  }

  function handleResize() {
    if (showPicker.value)
      updateDropdownPosition();
  }

  function handleScroll() {
    if (showPicker.value)
      updateDropdownPosition();
  }

  onMounted(() => {
    document.addEventListener('keydown', handleEscape);
    window.addEventListener('resize', handleResize);
    window.addEventListener('scroll', handleScroll, true);
  });

  onUnmounted(() => {
    document.removeEventListener('keydown', handleEscape);
    window.removeEventListener('resize', handleResize);
    window.removeEventListener('scroll', handleScroll, true);
  });
</script>

<style scoped>
  .color-picker-dropdown {
    border: 1px solid #dee2e6;
    background: white;
    border-radius: 0.375rem;
    overflow-y: auto;
  }

  .color-picker-backdrop {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 9998;
    background: transparent;
  }

  .preset-colors-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(32px, 1fr));
    gap: 8px;
    max-height: 120px;
    overflow-y: auto;
    padding: 4px;
    border: 1px solid #e9ecef;
    border-radius: 0.375rem;
    background: #f8f9fa;
  }

  .preset-color-btn {
    width: 32px;
    height: 32px;
    border: 2px solid #dee2e6;
    border-radius: 0.25rem;
    cursor: pointer;
    transition: all 0.2s ease;
    padding: 0;
    background: none;
  }

  .preset-color-btn:hover {
    transform: scale(1.1);
    border-color: #6c757d;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  }

  .preset-color-btn.selected {
    border-color: #0d6efd;
    border-width: 3px;
    transform: scale(1.05);
    box-shadow: 0 0 0 2px rgba(13, 110, 253, 0.25);
  }

  .form-control-color {
    border-radius: 0.375rem;
    height: 38px;
    padding: 1px;
  }

  .form-control-color::-webkit-color-swatch-wrapper {
    padding: 2px;
    border-radius: 0.25rem;
  }

  .form-control-color::-webkit-color-swatch {
    border: none;
    border-radius: 0.125rem;
  }

  .form-control-color::-moz-color-swatch {
    border: none;
    border-radius: 0.125rem;
  }

  /* Ensure the grid scrolls properly */
  .preset-colors-grid::-webkit-scrollbar {
    width: 6px;
  }

  .preset-colors-grid::-webkit-scrollbar-track {
    background: #f1f1f1;
    border-radius: 3px;
  }

  .preset-colors-grid::-webkit-scrollbar-thumb {
    background: #c1c1c1;
    border-radius: 3px;
  }

  .preset-colors-grid::-webkit-scrollbar-thumb:hover {
    background: #a8a8a8;
  }
</style>
