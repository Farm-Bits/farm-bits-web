<template>
  <CContainer fluid class="py-3">
    <div class="d-flex align-items-center mb-3">
      <Link :href="routePath('programs_index')" class="btn btn-link p-0 me-3">
        <CIcon name="cilArrowLeft" />
      </Link>
      <h1 class="h3 mb-0">{{ source.name }}</h1>
    </div>

    <CCard>
      <CCardBody>
        <div v-if="programs.length === 0" class="text-center text-muted py-5">
          No programs found on this device.
        </div>

        <template v-else>
          <CButtonGroup role="group" aria-label="Select program" class="mb-3 flex-wrap">
            <CButton
              v-for="program in programs"
              :key="program.index"
              :color="program.index === selectedIndex ? 'primary' : 'secondary'"
              :variant="program.index === selectedIndex ? undefined : 'outline'"
              :aria-pressed="program.index === selectedIndex"
              @click="selectProgram(program.index)">
              Program {{ program.index + 1 }}
            </CButton>
          </CButtonGroup>

          <ProgramTab
            v-if="selectedProgram"
            :key="selectedProgram.index"
            :program="selectedProgram"
            @update:has-pending-changes="activeHasPending = $event" />
        </template>
      </CCardBody>
    </CCard>
  </CContainer>
</template>

<script lang="ts" setup>
  import { ref, computed } from 'vue';
  import ProgramTab from './ProgramTab.vue';
  import useAuth from '@/composables/useAuth';
  import type { Program, ProgramSource } from './types';

  const { pageProps, routePath } = useAuth<{
    source: ProgramSource;
    programs: Program[];
  }>();

  const source = computed(() => pageProps.value.source);
  const programs = computed(() => pageProps.value.programs);

  const selectedIndex = ref<number>(programs.value[0]?.index ?? 0);
  const selectedProgram = computed(() =>
    programs.value.find((program) => program.index === selectedIndex.value) ?? null
  );

  // Tracks whether the currently shown program has unsaved edits, so switching
  // programs (which remounts ProgramTab and drops its pending state) can warn.
  const activeHasPending = ref(false);

  function selectProgram(index: number) {
    if (index === selectedIndex.value)
      return;

    if (activeHasPending.value && !window.confirm('Discard unsaved changes to this program?'))
      return;

    activeHasPending.value = false;
    selectedIndex.value = index;
  }
</script>

<style scoped>
</style>
