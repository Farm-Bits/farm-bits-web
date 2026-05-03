<template>
  <CContainer fluid class="px-4 py-4">
    <!-- Header with Breadcrumb -->
    <CRow class="mb-3 align-items-center">
      <div class="col d-flex justify-content-between align-items-start">
        <h1 class="h3 mb-1">Programs — {{ source.name }}</h1>
      </div>
    </CRow>

    <CCardBody>
      <CNav variant="tabs" class="mb-3">
        <CNavItem v-for="program in programs" :key="program.index">
          <CNavLink
            :active="activeProgramIndex === program.index"
            href="javascript:void(0)"
            @click="activeProgramIndex = program.index">
            Program {{ program.index }}
          </CNavLink>
        </CNavItem>
      </CNav>

      <ProgramTab
        v-if="activeProgram"
        :key="activeProgram.index"
        :program="activeProgram"
        :group-labels="group_labels" />
    </CCardBody>
  </CContainer>
</template>

<script setup lang="ts">
  import { ref, computed } from 'vue';
  import ProgramTab from './components/ProgramTab.vue';
  import type { Program } from './types';

  type SourceKind = 'plc' | 'modbus_device';

  type SourceSummary = {
    kind: SourceKind;
    id: number;
    name: string;
    firmware: string | null;
  };

  const props = defineProps<{
    source: SourceSummary;
    programs: Program[];
    group_labels: Record<string, string>;
  }>();

  const activeProgramIndex = ref<number>(props.programs[0]?.index ?? 0);

  const activeProgram = computed<Program | undefined>(() =>
    props.programs.find((p) => p.index === activeProgramIndex.value)
  );
</script>
