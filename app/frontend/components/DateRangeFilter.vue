<template>
  <div class="date-range-filter">
    <CFormLabel class="mb-1 small text-body-secondary">Date Range</CFormLabel>
    <div class="d-flex align-items-center gap-2">
      <CFormSelect
        v-model="selectedPreset"
        size="sm"
        class="preset-select"
        @update:model-value="handlePresetChange">
        <option value="today">Today</option>
        <option value="yesterday">Yesterday</option>
        <option value="last_7_days">Last 7 Days</option>
        <option value="last_30_days">Last 30 Days</option>
        <option value="custom">Custom</option>
      </CFormSelect>
      <template v-if="selectedPreset === 'custom'">
        <CFormInput
          type="date"
          size="sm"
          :model-value="dateRange.start"
          @update:model-value="handleStartChange"
        />
        <span class="text-body-secondary">to</span>
        <CFormInput
          type="date"
          size="sm"
          :model-value="dateRange.end"
          @update:model-value="handleEndChange"
        />
      </template>
      <template v-else>
        <span class="small text-body-secondary">
          {{ formatDateRange(dateRange) }}
        </span>
      </template>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { ref, watch } from 'vue';

  export type DateRange = {
    start: string;
    end: string;
  };
  type DateRangePreset = 'today' | 'yesterday' | 'last_7_days' | 'last_30_days' | 'custom';

  const { modelValue } = defineProps<{
    modelValue: DateRange;
  }>();

  const emit = defineEmits<{
    (e: 'update:modelValue', value: DateRange): void;
  }>();

  const selectedPreset = ref<DateRangePreset>('today');
  const dateRange = ref<DateRange>({ ...modelValue });

  function today() {
    return new Date().toISOString().slice(0, 10);
  }

  function daysAgo(n: number) {
    const d = new Date();
    d.setDate(d.getDate() - n);
    return d.toISOString().slice(0, 10);
  }

  function getPresetRange(preset: DateRangePreset): DateRange {
    switch (preset) {
      case 'today':
        return { start: today(), end: today() };
      case 'yesterday':
        return { start: daysAgo(1), end: daysAgo(1) };
      case 'last_7_days':
        return { start: daysAgo(6), end: today() };
      case 'last_30_days':
        return { start: daysAgo(29), end: today() };
      default:
        return { ...dateRange.value };
    }
  }

  function handlePresetChange(preset: string) {
    selectedPreset.value = preset as DateRangePreset;
    if (preset !== 'custom') {
      const range = getPresetRange(preset as DateRangePreset);
      dateRange.value = range;
      emit('update:modelValue', range);
    }
  }

  function handleStartChange(value: string) {
    dateRange.value.start = value;
    emit('update:modelValue', { ...dateRange.value });
  }

  function handleEndChange(value: string) {
    dateRange.value.end = value;
    emit('update:modelValue', { ...dateRange.value });
  }

  function formatDateRange(range: DateRange) {
    if (range.start === range.end)
      return formatDate(range.start);

    return `${formatDate(range.start)} – ${formatDate(range.end)}`;
  }

  function formatDate(dateStr: string) {
    const d = new Date(dateStr + 'T00:00:00');
    return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
  }

  watch(
    () => modelValue,
    (val) => {
      dateRange.value = { ...val };
    }
  );
</script>

<style scoped>
  .preset-select {
    min-width: 130px;
    max-width: 150px;
  }
</style>
