<template>
  <CContainer fluid class="p-4">
    <div class="d-flex justify-content-between align-items-center mb-2">
      <div>
        <h5 class="mb-1">Device Management</h5>
        <p class="text-medium-emphasis small mb-0">
          Manage devices
        </p>
      </div>
      <CButton
        v-if="canAddDevice"
        color="primary"
        @click="openAddDeviceModal">
        <CIcon icon="cilPlus" class="me-2" />
        Add Device
      </CButton>
    </div>

    <!-- Empty State -->
    <div v-if="flatRows.length === 0" class="text-center py-5">
      <CIcon icon="cilRouter" size="4xl" class="text-muted mb-3" />
      <h4 class="text-muted mb-2">No equipment yet</h4>
      <p class="text-muted mb-0">
        Equipment will appear here once it's been provisioned for this site.
      </p>
    </div>

    <!-- Equipment Table -->
    <CCard v-else class="shadow-sm devices-card">
      <CTable hover responsive class="mb-0 align-middle devices-table">
        <colgroup>
          <col style="width: 40%;">
          <col style="width: 22%;">
          <col style="width: 24%;">
          <col style="width: 14%;">
        </colgroup>
        <CTableHead class="bg-light">
          <CTableRow>
            <CTableHeaderCell class="ps-4">Name</CTableHeaderCell>
            <CTableHeaderCell>Type</CTableHeaderCell>
            <CTableHeaderCell>Status</CTableHeaderCell>
            <CTableHeaderCell class="text-end pe-4"></CTableHeaderCell>
          </CTableRow>
        </CTableHead>
        <CTableBody>
          <CTableRow
            v-for="row in flatRows"
            :key="row.row_key"
            :class="rowClass(row)">

            <CTableDataCell class="ps-4">
              <div class="row-name-cell" :style="{ paddingLeft: `${row.depth * 24}px` }">
                <span
                  v-for="(visible, i) in row.ancestor_lines"
                  :key="i"
                  class="ancestor-line"
                  :class="{ invisible: !visible }"
                  :style="{ left: `${i * 24 + 14}px` }" />

                <template v-if="row.depth > 0">
                  <span
                    class="elbow-vertical"
                    :class="{ 'elbow-vertical-stub': row.is_last_child }"
                    :style="{ left: `${(row.depth - 1) * 24 + 14}px` }" />
                  <span
                    class="elbow-horizontal"
                    :style="{ left: `${(row.depth - 1) * 24 + 14}px` }" />
                </template>

                <span class="row-icon">
                  <CIcon :icon="iconForKind(row.kind)" :size="row.depth === 0 ? 'lg' : undefined" />
                </span>
                <span class="row-name" :class="{ 'row-name-strong': row.depth === 0, 'text-muted': row.status === 'awaiting_setup' }">
                  {{ row.name || displayPlaceholder(row) }}
                </span>
              </div>
            </CTableDataCell>

            <CTableDataCell class="text-muted">
              {{ row.display_type }}
            </CTableDataCell>

            <CTableDataCell>
              <StatusBadge :row="row" />
            </CTableDataCell>

            <CTableDataCell class="text-end pe-4">
              <RowActions
                :row="row"
                @configure="handleConfigure"
                @setup="handleSetup"
                @edit="handleEdit"
                @remove="handleRemove" />
            </CTableDataCell>
          </CTableRow>
        </CTableBody>
      </CTable>
    </CCard>

    <!-- ── Add Device Modal ─────────────────────────────────── -->
    <CModal
      :visible="addOpen"
      @close="closeAddModal"
      size="lg"
      backdrop="static">
      <CModalHeader>
        <CModalTitle>Add a device</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <AddDeviceForm
          :options="addDeviceOptions"
          @success="onAddSuccess"
          @cancel="closeAddModal" />
      </CModalBody>
    </CModal>

    <!-- ── Setup Modal ──────────────────────────────────────── -->
    <CModal
      :visible="modals.setupOpen.value"
      @close="modals.close()"
      size="lg"
      backdrop="static">
      <CModalHeader>
        <CModalTitle>
          {{ modals.selectedRow.value?.kind === 'gateway' ? 'Set up gateway' : 'Set up controller' }}
        </CModalTitle>
      </CModalHeader>
      <CModalBody>
        <SetupGatewayForm
          v-if="modals.selectedRow.value && modals.selectedRow.value.kind === 'gateway'"
          :row="modals.selectedRow.value"
          @success="onMutationSuccess"
          @cancel="modals.close()" />
        <SetupPlcForm
          v-else-if="modals.selectedRow.value && modals.selectedRow.value.kind === 'plc'"
          :row="modals.selectedRow.value"
          :availableGateways="activeGatewayHosts"
          @success="onMutationSuccess"
          @cancel="modals.close()" />
      </CModalBody>
    </CModal>

    <!-- ── Edit Modal ───────────────────────────────────────── -->
    <CModal
      :visible="modals.editOpen.value"
      @close="modals.close()"
      size="lg"
      backdrop="static">
      <CModalHeader>
        <CModalTitle>
          {{ editModalTitle }}
        </CModalTitle>
      </CModalHeader>
      <CModalBody>
        <EditGatewayForm
          v-if="modals.selectedRow.value && modals.selectedRow.value.kind === 'gateway'"
          :row="modals.selectedRow.value"
          @success="onMutationSuccess"
          @cancel="modals.close()" />
        <EditPlcForm
          v-else-if="modals.selectedRow.value && modals.selectedRow.value.kind === 'plc'"
          :row="modals.selectedRow.value"
          :availableGateways="activeGatewayHosts"
          @success="onMutationSuccess"
          @cancel="modals.close()" />
        <EditModbusDeviceForm
          v-else-if="modals.selectedRow.value && modals.selectedRow.value.kind === 'modbus_device'"
          :row="modals.selectedRow.value"
          @success="onMutationSuccess"
          @cancel="modals.close()" />
      </CModalBody>
    </CModal>

    <!-- ── Remove Modal ─────────────────────────────────────── -->
    <CModal
      :visible="modals.removeOpen.value"
      @close="modals.close()"
      backdrop="static">
      <CModalHeader>
        <CModalTitle>Confirm removal</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <RemoveConfirmDialog
          v-if="modals.selectedRow.value"
          :row="modals.selectedRow.value"
          @success="onMutationSuccess"
          @cancel="modals.close()" />
      </CModalBody>
    </CModal>
  </CContainer>
</template>

<script lang="ts" setup>
  import { computed, ref } from 'vue';
  import { router } from '@inertiajs/vue3';
  import StatusBadge from './components/StatusBadge.vue';
  import RowActions from './components/RowActions.vue';
  import SetupGatewayForm from './components/SetupGatewayForm.vue';
  import SetupPlcForm from './components/SetupPlcForm.vue';
  import EditGatewayForm from './components/EditGatewayForm.vue';
  import EditPlcForm from './components/EditPlcForm.vue';
  import EditModbusDeviceForm from './components/EditModbusDeviceForm.vue';
  import RemoveConfirmDialog from './components/RemoveConfirmDialog.vue';
  import AddDeviceForm from './components/AddDeviceForm.vue';
  import useDeviceModals from './composables/useDeviceModals';
  import useAuth from '@/composables/useAuth';
  import usePermissions from '@/composables/usePermissions';
  import type {
    DeviceRow,
    DeviceKind,
    FlatDeviceRow,
    AddDeviceOptions,
    EligibleHost,
  } from './types';

  const { permissions } = usePermissions();
  const { pageProps, routePath } = useAuth<{
    tree: DeviceRow[];
    add_device_options: AddDeviceOptions;
  }>();

  const tree = ref<DeviceRow[]>(pageProps.value.tree);
  const addDeviceOptions = ref<AddDeviceOptions>(pageProps.value.add_device_options);

  const modals = useDeviceModals();
  const addOpen = ref(false);

  // ── Tree flattening ────────────────────────────────────────────────

  function flatten(rows: DeviceRow[]): FlatDeviceRow[] {
    const out: FlatDeviceRow[] = [];

    function walk(nodes: DeviceRow[], depth: number, ancestor_lines: boolean[]) {
      nodes.forEach((node, idx) => {
        const isLast = idx === nodes.length - 1;
        out.push({
          ...node,
          depth,
          is_last_child: isLast,
          ancestor_lines,
        } as FlatDeviceRow);

        if (node.children.length > 0) {
          const childAncestorLines = [...ancestor_lines, !isLast];
          walk(node.children, depth + 1, childAncestorLines);
        }
      });
    }

    walk(rows, 0, []);
    return out;
  }

  const flatRows = computed<FlatDeviceRow[]>(() => flatten(tree.value));

  const activeGatewayHosts = computed<EligibleHost[]>(() => {
    return addDeviceOptions.value.hosts.gateways;
  });

  // ── Render helpers ─────────────────────────────────────────────────

  function iconForKind(kind: DeviceKind) {
    switch (kind) {
      case 'gateway':
        return 'cilRouter';
      case 'plc':
        return 'cilMemory';
      case 'modbus_device':
        return 'cilSpreadsheet';
    }
  }

  function displayPlaceholder(row: DeviceRow) {
    if (row.kind === 'gateway')
      return 'Unnamed gateway';

    if (row.kind === 'plc')
      return 'Unnamed controller';

    return 'Unnamed device';
  }

  function rowClass(row: FlatDeviceRow) {
    return {
      'row-child': row.depth > 0,
      'row-disabled': row.status === 'disabled',
      'row-awaiting': row.status === 'awaiting_setup',
    };
  }

  const editModalTitle = computed(() => {
    const r = modals.selectedRow.value;
    if (!r)
      return 'Edit';

    if (r.kind === 'gateway')
      return 'Edit gateway';

    if (r.kind === 'plc')
      return 'Edit controller';

    return 'Edit device';
  });

  // ── Header / actions wiring ────────────────────────────────────────

  const canAddDevice = computed(() => {
    return permissions.value?.modbus_devices?.create === true;
  });

  function openAddDeviceModal() {
    addOpen.value = true;
  }

  function closeAddModal() {
    addOpen.value = false;
  }

  function onAddSuccess() {
    closeAddModal();
    router.reload({ only: ['tree', 'add_device_options'] });
  }

  function handleConfigure(row: FlatDeviceRow) {
    if (row.kind === 'plc' && permissions.value?.plcs?.show) {
      router.visit(routePath('plcs_show', { id: row.id }));
      return;
    }

    if (row.kind === 'modbus_device' && permissions.value?.modbus_devices?.show) {
      router.visit(routePath('modbus_devices_show', { id: row.id }));
      return;
    }

    if (row.kind === 'gateway')
      handleEdit(row);
  }

  function handleSetup(row: FlatDeviceRow) {
    modals.openSetup(row);
  }

  function handleEdit(row: FlatDeviceRow) {
    modals.openEdit(row);
  }

  function handleRemove(row: FlatDeviceRow) {
    modals.openRemove(row);
  }

  function onMutationSuccess() {
    modals.close();
    router.reload({ only: ['tree', 'add_device_options'] });
  }
</script>

<style scoped>
  .devices-card {
    overflow: hidden;
  }

  .devices-table :deep(thead th) {
    font-weight: 500;
    font-size: 0.78rem;
    color: var(--cui-secondary-color, #6c757d);
    letter-spacing: 0.02em;
  }

  .row-name-cell {
    position: relative;
    display: flex;
    align-items: center;
    gap: 10px;
    min-height: 28px;
  }

  .row-icon {
    color: var(--cui-secondary-color, #6c757d);
    display: inline-flex;
    align-items: center;
  }

  .row-name {
    font-size: 0.95rem;
  }

  .row-name-strong {
    font-weight: 500;
  }

  .ancestor-line {
    position: absolute;
    top: 0;
    bottom: 0;
    width: 1px;
    background-color: var(--cui-border-color-translucent, rgba(0, 0, 0, 0.12));
  }

  .ancestor-line.invisible {
    background-color: transparent;
  }

  .elbow-vertical {
    position: absolute;
    top: 0;
    height: 50%;
    width: 1px;
    background-color: var(--cui-border-color-translucent, rgba(0, 0, 0, 0.12));
  }

  .elbow-vertical-stub {
    height: 50%;
  }

  .elbow-horizontal {
    position: absolute;
    top: 50%;
    width: 14px;
    height: 1px;
    background-color: var(--cui-border-color-translucent, rgba(0, 0, 0, 0.12));
  }

  .row-child {
    background-color: var(--cui-tertiary-bg, rgba(0, 0, 0, 0.02));
  }

  .row-disabled .row-name,
  .row-awaiting .row-name {
    color: var(--cui-secondary-color, #6c757d);
  }

  .status-dot {
    display: inline-block;
    width: 8px;
    height: 8px;
    border-radius: 50%;
    vertical-align: 1px;
  }
  .status-online   { background-color: var(--cui-success, #198754); }
  .status-offline  { background-color: var(--cui-warning, #ffc107); }
  .status-awaiting { background-color: var(--cui-secondary, #6c757d); }
</style>
