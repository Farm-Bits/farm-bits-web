
<template>
  <CContainer fluid class="px-4 py-4">
    <!-- Header with Breadcrumb -->
    <CRow class="mb-3 align-items-center">
      <div class="col d-flex justify-content-between align-items-start">
        <h1 class="h3 mb-1">Programs</h1>
      </div>
    </CRow>

    <CCardBody>
      <div v-if="!hasSources" class="text-medium-emphasis text-center py-4">
        No devices with programs are available on this site.
      </div>

      <CTable v-else hover responsive>
        <CTableHead>
          <CTableRow>
            <CTableHeaderCell>Name</CTableHeaderCell>
            <CTableHeaderCell>Type</CTableHeaderCell>
            <CTableHeaderCell>Firmware</CTableHeaderCell>
            <CTableHeaderCell>Host</CTableHeaderCell>
            <CTableHeaderCell>Status</CTableHeaderCell>
            <CTableHeaderCell>Last seen</CTableHeaderCell>
          </CTableRow>
        </CTableHead>

        <CTableBody>
          <CTableRow
            v-for="source in sources"
            :key="source.row_key"
            class="cursor-pointer"
            @click="navigateToSource(source)">
            <CTableDataCell>
              <strong>{{ source.name }}</strong>
            </CTableDataCell>
            <CTableDataCell>{{ source.display_type }}</CTableDataCell>
            <CTableDataCell>{{ source.firmware ?? '—' }}</CTableDataCell>
            <CTableDataCell>{{ source.host ?? '—' }}</CTableDataCell>
            <CTableDataCell>
              <CBadge :color="STATUS_VARIANTS[source.status]">
                {{ STATUS_LABELS[source.status] }}
              </CBadge>
            </CTableDataCell>
            <CTableDataCell>{{ formatLastSeen(source.last_seen_at) }}</CTableDataCell>
          </CTableRow>
        </CTableBody>
      </CTable>
    </CCardBody>
  </CContainer>
</template>

<script setup lang="ts">
  import { computed } from 'vue';
  import { router } from '@inertiajs/vue3';

  type SourceKind = 'plc' | 'modbus_device';
  type Status = 'online' | 'offline' | 'awaiting_setup' | 'disabled';

  type ProgramSource = {
    row_key: string;
    kind: SourceKind;
    id: number;
    name: string;
    display_type: string;
    firmware: string | null;
    host: string | null;
    status: Status;
    last_seen_at: string | null;
    active: boolean;
  };

  const props = defineProps<{
    sources: ProgramSource[]
  }>();

  const hasSources = computed(() => props.sources.length > 0);

  const STATUS_VARIANTS: Record<Status, string> = {
    online:          'success',
    offline:         'danger',
    awaiting_setup:  'warning',
    disabled:        'secondary'
  };

  const STATUS_LABELS: Record<Status, string> = {
    online:          'Online',
    offline:         'Offline',
    awaiting_setup:  'Awaiting setup',
    disabled:        'Disabled'
  };

  function formatLastSeen(iso: string | null) {
    if (!iso)
      return '—';

    const date = new Date(iso);
    return date.toLocaleString();
  }

  function navigateToSource(source: ProgramSource) {
    const path = source.kind === 'plc'
      ? `/user/programs/plc/${source.id}`
      : `/user/programs/modbus_device/${source.id}`;

    router.visit(path);
  }
</script>

<style scoped>
  .cursor-pointer {
    cursor: pointer;
  }
</style>
