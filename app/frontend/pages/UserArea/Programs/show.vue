<template>
  <CContainer fluid class="py-3">
    <div class="d-flex align-items-center mb-3">
      <Link :href="routePath('programs_index')" class="btn btn-link p-0 me-3">
        <CIcon icon="cilArrowLeft" />
      </Link>
      <h1 class="h3 mb-0">{{ source.name }}</h1>
    </div>

    <CCard>
      <CCardBody>
        <div v-if="programs.length === 0" class="text-center text-muted py-5">
          No programs found on this device.
        </div>

        <template v-else>
          <!-- View selector. Picking a program only changes what's shown; it
               never changes which program the device is running. -->
          <CButtonGroup role="group" aria-label="Select program to view" class="mb-3 flex-wrap">
            <CButton
              v-for="program in programs"
              :key="program.index"
              :color="program.index === selectedIndex ? 'primary' : 'secondary'"
              :variant="program.index === selectedIndex ? undefined : 'outline'"
              :aria-pressed="program.index === selectedIndex"
              @click="selectProgram(program.index)">
              Program {{ program.index + 1 }}
              <CBadge v-if="program.index === activeProgramIndex" color="success" class="ms-1">
                Active
              </CBadge>
            </CButton>
          </CButtonGroup>

          <!-- Active-program control, distinct from the view selector. -->
          <div v-if="activeSelector" class="d-flex align-items-center gap-2 mb-3">
            <template v-if="selectedIsActive">
              <CBadge color="success">Active program</CBadge>
              <span class="text-muted small">
                This is the program the device is currently running.
              </span>
            </template>
            <CButton
              v-else
              color="success"
              variant="outline"
              size="sm"
              :disabled="isSettingActive"
              @click="setActiveProgram">
              <CSpinner v-if="isSettingActive" component="span" size="sm" class="me-1" />
              Set Program {{ (selectedProgram?.index ?? 0) + 1 }} as active
            </CButton>
          </div>

          <!-- Sync state + on-demand refresh from the device. -->
          <div
            v-if="source.kind === 'modbus_device' && selectedProgram"
            class="d-flex justify-content-between align-items-center mb-2">
            <span class="text-muted small">
              <template v-if="selectedSyncedAt">
                Synced <RelativeTime :datetime="selectedSyncedAt" /> from device
              </template>
              <template v-else>
                Not yet synced from device
              </template>
            </span>
            <CButton color="light" size="sm" :disabled="isRefreshing" @click="refreshProgram">
              <CSpinner v-if="isRefreshing" component="span" size="sm" class="me-1" />
              <CIcon v-else icon="cilReload" class="me-1" />
              Refresh from device
            </CButton>
          </div>

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
  import { Link, router } from '@inertiajs/vue3';
  import axios from 'axios';
  import ProgramTab from './ProgramTab.vue';
  import RelativeTime from '@/components/RelativeTime.vue';
  import useAuth from '@/composables/useAuth';
  import { useApiCall } from '@/composables/useApi';
  import type { RegisterMapping } from '@/types/plc';
  import type { Program, ProgramSource } from './types';

  // The refresh job pulls from the device and reads back asynchronously; this
  // is how long we wait before partial-reloading to pick up fresh values.
  const REFRESH_SETTLE_MS = 7000;

  const { pageProps, routePath } = useAuth<{
    source: ProgramSource;
    programs: Program[];
    active_selector: RegisterMapping | null;
  }>();

  const { execute } = useApiCall();

  const source = computed(() => pageProps.value.source);
  const programs = computed(() => pageProps.value.programs);
  const activeSelector = computed(() => pageProps.value.active_selector);

  const selectedIndex = ref<number>(programs.value[0]?.index ?? 0);
  const selectedProgram = computed(() =>
    programs.value.find((program) => program.index === selectedIndex.value) ?? null
  );

  // Active program, as reported by the device's program_select register.
  // Held in a ref so a successful "set active" updates it without a reload.
  const activeProgramIndex = ref<number | null>(
    activeSelector.value ? Number(activeSelector.value.measurement_point.last_value) : null
  );

  const selectedIsActive = computed(() =>
    selectedProgram.value !== null && selectedProgram.value.index === activeProgramIndex.value
  );

  // Latest read time across the selected program's registers — the program's
  // values come from the host mirror, so this is how fresh they are.
  const selectedSyncedAt = computed<string | null>(() => {
    const program = selectedProgram.value;
    if (program === null)
      return null;

    const mappings: RegisterMapping[] = [
      ...(program.meta?.registers ?? []),
      ...program.phases.flatMap((phase) => phase.registers)
    ];

    let latest: string | null = null;
    mappings.forEach((rm) => {
      const at = rm.measurement_point.last_value_at;
      if (at && (latest === null || at > latest))
        latest = at;
    });

    return latest;
  });

  // Tracks whether the currently shown program has unsaved edits, so switching
  // programs (which remounts ProgramTab and drops its pending state) can warn.
  const activeHasPending = ref(false);
  const isSettingActive = ref(false);
  const isRefreshing = ref(false);

  function selectProgram(index: number) {
    if (index === selectedIndex.value)
      return;

    if (activeHasPending.value && !window.confirm('Discard unsaved changes to this program?'))
      return;

    activeHasPending.value = false;
    selectedIndex.value = index;
  }

  async function setActiveProgram() {
    const selector = activeSelector.value;
    const program = selectedProgram.value;
    if (!selector || program === null || program.index === activeProgramIndex.value)
      return;

    const programNumber = program.index + 1;
    const confirmed = window.confirm(
      `Make Program ${programNumber} the active program on ${source.value.name}? ` +
      'This changes which program the device runs.'
    );
    if (!confirmed)
      return;

    isSettingActive.value = true;

    const { success } = await execute(
      () => axios.post(
        routePath('measurement_points_write', { id: selector.measurement_point.id }),
        { value: program.index }
      ),
      {
        showSuccessToast: true,
        successMessage: `Program ${programNumber} is now active`,
        showErrorToast: true,
        errorTitle: 'Failed to set active program'
      }
    );

    if (success)
      activeProgramIndex.value = program.index;

    isSettingActive.value = false;
  }

  async function refreshProgram() {
    const program = selectedProgram.value;
    if (program === null || source.value.kind !== 'modbus_device' || isRefreshing.value)
      return;

    isRefreshing.value = true;

    const { success } = await execute(
      () => axios.post(
        routePath('modbus_device_programs_refresh', { id: source.value.id }),
        { program_indices: [program.index] }
      ),
      {
        showSuccessToast: true,
        successMessage: `Refreshing Program ${program.index + 1} from the device…`,
        showErrorToast: true,
        errorTitle: 'Refresh failed'
      }
    );

    if (!success) {
      isRefreshing.value = false;
      return;
    }

    window.setTimeout(() => {
      router.reload({
        only: ['programs', 'active_selector'],
        onFinish: () => { isRefreshing.value = false; }
      });
    }, REFRESH_SETTLE_MS);
  }
</script>

<style scoped>
</style>
