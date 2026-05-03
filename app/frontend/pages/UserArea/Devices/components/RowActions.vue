<template>
  <div class="d-inline-flex align-items-center gap-2">
    <!-- Primary action button (inline link, not a heavy button) -->
    <a
      v-if="primaryAction"
      href="#"
      class="row-action-link"
      :class="primaryAction.class"
      @click.prevent="primaryAction.handler">
      {{ primaryAction.label }}
    </a>

    <!-- Overflow dropdown for secondary actions -->
    <CDropdown v-if="hasSecondaryActions" class="row-action-dropdown">
      <CDropdownToggle color="light" size="sm" :caret="false" class="border-0">
        <CIcon icon="cilOptions" />
      </CDropdownToggle>
      <CDropdownMenu>
        <CDropdownItem
          v-if="canEdit"
          @click="$emit('edit', row)">
          <CIcon icon="cilPencil" class="me-2" />
          Edit
        </CDropdownItem>
        <template v-if="canRemove">
          <CDropdownDivider />
          <CDropdownItem class="text-danger" @click="$emit('remove', row)">
            <CIcon icon="cilTrash" class="me-2" />
            Remove
          </CDropdownItem>
        </template>
      </CDropdownMenu>
    </CDropdown>
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
  import usePermissions from '@/composables/usePermissions';
  import type { FlatDeviceRow } from '../types';

  const props = defineProps<{ row: FlatDeviceRow }>();
  const emit = defineEmits<{
    (e: 'configure', row: FlatDeviceRow): void;
    (e: 'setup', row: FlatDeviceRow): void;
    (e: 'edit', row: FlatDeviceRow): void;
    (e: 'remove', row: FlatDeviceRow): void;
  }>();

  const { permissions } = usePermissions();

  // ── Permission helpers per kind ─────────────────────────────────────

  const canConfigure = computed(() => {
    if (props.row.kind === 'plc')
      return permissions.value?.plcs?.show === true;

    if (props.row.kind === 'modbus_device')
      return permissions.value?.modbus_devices?.show === true;

    return false;
  });

  const canEdit = computed(() => {
    if (props.row.kind === 'gateway')
      return permissions.value?.gateways?.update === true;

    if (props.row.kind === 'plc')
      return permissions.value?.plcs?.update === true;

    if (props.row.kind === 'modbus_device')
      return permissions.value?.modbus_devices?.update === true;

    return false;
  });

  const canRemove = computed(() => {
    if (props.row.kind === 'modbus_device')
      return permissions.value?.modbus_devices?.destroy === true;

    return false;
  });

  // ── Primary action (the one inline link the row shows) ─────────────

  const primaryAction = computed(() => {
    if (props.row.status === 'awaiting_setup') {
      if (!canEdit.value)
        return null;
      return {
        label: 'Set up',
        class: 'text-primary',
        handler: () => emit('setup', props.row),
      };
    }

    if (canConfigure.value) {
      return {
        label: 'Configure',
        class: 'text-secondary',
        handler: () => emit('configure', props.row),
      };
    }

    return null;
  });

  const hasSecondaryActions = computed(() => {
    // For awaiting_setup rows the primary IS the edit, no overflow needed.
    if (props.row.status === 'awaiting_setup')
      return false;

    return canEdit.value || canRemove.value;
  });
</script>

<style scoped>
  .row-action-link {
    text-decoration: none;
    font-size: 0.9rem;
  }
  .row-action-link:hover {
    text-decoration: underline;
  }
  .row-action-dropdown :deep(.dropdown-toggle) {
    padding: 0.25rem 0.5rem;
    background: transparent;
  }
</style>
