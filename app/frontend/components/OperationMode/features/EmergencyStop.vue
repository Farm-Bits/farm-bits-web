<template>
  <div
    class="p-3 rounded border"
    :class="isActive ? 'border-danger bg-danger-subtle' : 'border-light'">
    <div class="d-flex align-items-center justify-content-between mb-2">
      <div>
        <strong class="d-block">{{ registerTemplate?.name ?? 'Emergency Stop' }}</strong>
        <small
          v-if="registerTemplate?.description"
          class="text-body-secondary">
          {{ registerTemplate.description }}
        </small>
      </div>
    </div>

    <CButton
      :color="isActive ? 'danger' : 'outline-danger'"
      :disabled="isWriting"
      @click="handleToggle">
      {{ isActive ? clearLabel : activateLabel }}
    </CButton>
  </div>
</template>

<script lang="ts" setup>
  import { computed, ref as vueRef } from 'vue';
  import { useGroupRegisters } from '@/composables/useGroupRegisters';
  import type { MeasurementPoint } from '@/types/measurementPoint';
  import type { RegisterMapping } from '@/types/plc';
  import { OM_GROUPS, OM_ROLES } from '@/types/operationMode';

  const { mappings } = defineProps<{
    mappings: RegisterMapping[];
  }>();

  const emit = defineEmits<{
    (e: 'write', measurementPointId: MeasurementPoint['id'], value: NonNullable<MeasurementPoint['last_value']>): void;
  }>();

  const mappingsRef = computed(() => mappings);
  const groupName = vueRef(OM_GROUPS.safety);
  const { getValue, mpForRole, templateForRole } = useGroupRegisters(mappingsRef, groupName);

  const isWriting = vueRef(false);

  const isActive = computed(() => getValue(OM_ROLES.emergencyStop) === '1');
  const registerTemplate = computed(() => templateForRole(OM_ROLES.emergencyStop));

  /**
   * Button labels derived from the register template's name.
   * If the register is named "Emergency Stop", buttons read
   * "Activate Emergency Stop" / "Clear Emergency Stop".
   */
  const registerName = computed(() => registerTemplate.value?.name ?? 'Emergency Stop');
  const activateLabel = computed(() => `Activate ${registerName.value}`);
  const clearLabel = computed(() => `Clear ${registerName.value}`);

  function handleToggle() {
    const mp = mpForRole(OM_ROLES.emergencyStop);
    if (!mp)
      return;

    isWriting.value = true;
    emit('write', mp.id, isActive.value ? 0 : 1);
    isWriting.value = false;
  }
</script>
