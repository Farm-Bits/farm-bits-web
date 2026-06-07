<template>
  <CContainer fluid class="p-4">
    <CCardBody>
      <div v-if="sources.length === 0" class="text-center text-muted py-5">
        <CIcon icon="cilList" size="3xl" class="mb-3" />
        <p class="mb-0">No devices with programs on this site.</p>
      </div>

      <CTable v-else hover responsive class="align-middle mb-0">
        <CTableHead>
          <CTableRow class="bg-light">
            <CTableHeaderCell style="width: 50px">Status</CTableHeaderCell>
            <CTableHeaderCell>Name</CTableHeaderCell>
            <CTableHeaderCell>Type</CTableHeaderCell>
            <CTableHeaderCell>Firmware</CTableHeaderCell>
          </CTableRow>
        </CTableHead>
        <CTableBody>
          <CTableRow
            v-for="source in sources"
            :key="`${source.kind}-${source.id}`"
            class="programs-row"
            @click="open(source)">
            <CTableDataCell>
              <ConnectionStatusIndicator :measurementPoint="{
                ...source,
                last_value_at: source.last_seen_at
              }" />
            </CTableDataCell>
            <CTableDataCell>
              <div class="fw-semibold">{{ source.name }}</div>
            </CTableDataCell>
            <CTableDataCell>
              <span>{{ source.display_type || defaultTypeLabel(source) }}</span>
            </CTableDataCell>
            <CTableDataCell>
              <span v-if="source.firmware" class="text-muted small">{{ source.firmware }}</span>
              <span v-else class="text-muted">—</span>
            </CTableDataCell>
          </CTableRow>
        </CTableBody>
      </CTable>
    </CCardBody>
  </CContainer>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import { router } from '@inertiajs/vue3';
  import ConnectionStatusIndicator from '@/components/ConnectionStatusIndicator.vue';
  import useAuth from '@/composables/useAuth';

  type ProgramSourceRow = {
    kind: 'plc' | 'modbus_device';
    id: number;
    name: string;
    display_type: string | null;
    firmware: string | null;
    host: string | null;
    active: boolean;
    last_seen_at: string | null;
  };

  const { pageProps, routePath } = useAuth<{ sources: ProgramSourceRow[] }>();

  const sources = computed(() => pageProps.value.sources);

  function defaultTypeLabel(source: ProgramSourceRow) {
    return source.kind === 'plc' ? 'Controller' : 'Device';
  }

  function open(source: ProgramSourceRow) {
    const key = source.kind === 'plc' ? 'programs_show_plc' : 'programs_show_modbus_device';
    router.visit(routePath(key, { id: source.id }));
  }
</script>

<style scoped>
  .programs-row {
    cursor: pointer;
  }
</style>
