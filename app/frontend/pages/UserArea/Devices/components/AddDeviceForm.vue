<template>
  <CForm @submit.prevent="submit">
    <p class="text-muted mb-4">
      Add a new device that connects through one of your gateways or controllers.
    </p>

    <!-- Step 1: Model -->
    <div class="mb-3">
      <CFormLabel>Device type <span class="text-danger">*</span></CFormLabel>
      <CFormSelect v-model="form.model_id" required>
        <option value="" selected disabled hidden>— Select a device type —</option>
        <option v-for="m in options.models" :key="m.id" :value="String(m.id)">
          {{ m.display_type || m.name }} — {{ m.full_name }}
        </option>
      </CFormSelect>
      <CFormText v-if="options.models.length === 0" class="text-warning">
        No device types available. Contact support to add device models to your catalog.
      </CFormText>
    </div>

    <!-- Step 2: Firmware (auto-selected when only one) -->
    <div v-if="firmwareOptions.length > 1" class="mb-3">
      <CFormLabel>Firmware version <span class="text-danger">*</span></CFormLabel>
      <CFormSelect v-model="form.modbus_firmware_version_id" required>
        <option value="" selected disabled hidden>— Select firmware —</option>
        <option v-for="f in firmwareOptions" :key="f.id" :value="String(f.id)">
          {{ f.name }}<span v-if="f.is_latest"> (latest)</span>
        </option>
      </CFormSelect>
    </div>

    <!-- Step 3: Connection mode -->
    <div v-if="form.model_id" class="mb-3">
      <CFormLabel>Connected via <span class="text-danger">*</span></CFormLabel>
      <div class="d-flex gap-3">
        <CFormCheck
          type="radio"
          name="host_kind"
          id="host_kind_gateway"
          :checked="form.host_kind === 'gateway'"
          @change="setHostKind('gateway')"
          :disabled="availableGateways.length === 0"
          label="Gateway (direct Modbus)" />
        <CFormCheck
          type="radio"
          name="host_kind"
          id="host_kind_plc"
          :checked="form.host_kind === 'plc'"
          @change="setHostKind('plc')"
          :disabled="availablePlcs.length === 0"
          label="Controller (bridged)" />
      </div>
      <CFormText v-if="form.host_kind === 'gateway'">
        The gateway polls this device directly over Modbus TCP/RTU.
      </CFormText>
      <CFormText v-else-if="form.host_kind === 'plc'">
        The controller bridges this device through its relay zone.
      </CFormText>
      <CFormText v-if="availableGateways.length === 0 && availablePlcs.length === 0" class="text-warning">
        No compatible hosts available for this device's Modbus protocol.
      </CFormText>
    </div>

    <!-- Step 4: Host selection -->
    <div v-if="form.host_kind === 'gateway'" class="mb-3">
      <CFormLabel>Gateway <span class="text-danger">*</span></CFormLabel>
      <CFormSelect v-model="form.gateway_id" required>
        <option value="" selected disabled hidden>— Select a gateway —</option>
        <option v-for="g in availableGateways" :key="g.id" :value="String(g.id)">
          {{ g.name }}
        </option>
      </CFormSelect>
    </div>

    <div v-if="form.host_kind === 'plc'" class="mb-3">
      <CFormLabel>Controller <span class="text-danger">*</span></CFormLabel>
      <CFormSelect v-model="form.plc_id" required>
        <option value="" selected disabled hidden>— Select a controller —</option>
        <option v-for="p in availablePlcs" :key="p.id" :value="String(p.id)">
          {{ p.name }}
        </option>
      </CFormSelect>
      <CFormText v-if="availablePlcs.length === 0" class="text-warning">
        No controllers with compatible firmware and Modbus protocol.
      </CFormText>
    </div>

    <!-- Step 5: Instance fields -->
    <div v-if="hostSelected" class="mb-3">
      <CFormLabel>Name <span class="text-danger">*</span></CFormLabel>
      <CFormInput
        v-model="form.name"
        :placeholder="namePlaceholder"
        required />
      <CFormText>How this device will appear in the equipment list.</CFormText>
    </div>

    <div v-if="hostSelected" class="mb-3">
      <CFormLabel>Modbus slave <span class="text-danger">*</span></CFormLabel>
      <CFormInput
        type="number"
        v-model.number="form.slave_id"
        min="1"
        max="247"
        required />
      <CFormText>The Modbus slave address (1–247) configured on the device.</CFormText>
    </div>

    <div v-if="form.host_kind === 'gateway' && hostSelected" class="mb-3">
      <CFormLabel>IP address <span class="text-danger">*</span></CFormLabel>
      <CFormInput
        v-model="form.private_ip"
        placeholder="192.168.1.100"
        required />
      <CFormText>The local IP address of this device on the gateway's network.</CFormText>
    </div>

    <div v-if="error" class="alert alert-danger small">{{ error }}</div>

    <div class="d-flex justify-content-end gap-2 mt-4">
      <CButton color="secondary" variant="outline" @click="$emit('cancel')" :disabled="submitting">
        Cancel
      </CButton>
      <CButton color="primary" type="submit" :disabled="submitting || !canSubmit">
        <span v-if="submitting" class="spinner-border spinner-border-sm me-2" />
        Add device
      </CButton>
    </div>
  </CForm>
</template>

<script lang="ts" setup>
  import { computed, reactive, ref, watch } from 'vue';
  import axios from 'axios';
  import { useApiCall } from '@/composables/useApi';
  import useAuth from '@/composables/useAuth';
  import type { AddDeviceOptions, EligibleHost, AddDeviceModelOption } from '../types';

  const props = defineProps<{ options: AddDeviceOptions }>();
  const emit = defineEmits<{
    (e: 'success'): void;
    (e: 'cancel'): void;
  }>();

  const { execute } = useApiCall();
  const { routePath } = useAuth();

  type HostKind = 'gateway' | 'plc';

  const form = reactive<{
    model_id: string;
    modbus_firmware_version_id: string;
    host_kind: HostKind | null;
    gateway_id: string;
    plc_id: string;
    name: string;
    slave_id: number | null;
    private_ip: string;
  }>({
    model_id: '',
    modbus_firmware_version_id: '',
    host_kind: null,
    gateway_id: '',
    plc_id: '',
    name: '',
    slave_id: null,
    private_ip: ''
  });

  const submitting = ref(false);
  const error = ref<string | null>(null);

  const selectedModel = computed<AddDeviceModelOption | null>(() => {
    if (form.model_id === '')
      return null;

    return props.options.models.find((m) => m.id === Number(form.model_id)) || null;
  });

  const firmwareOptions = computed(() => {
    return selectedModel.value?.firmware_versions || [];
  });

  function hostShareProtocolWithSelectedModel(host: EligibleHost): boolean {
    if (selectedModel.value === null)
      return false;

    if (host.supports_modbus_tcp && selectedModel.value.supports_modbus_tcp)
      return true;

    if (host.supports_modbus_rtu && selectedModel.value.supports_modbus_rtu)
      return true;

    return false;
  }

  const availableGateways = computed<EligibleHost[]>(() => {
    return props.options.hosts.gateways.filter(hostShareProtocolWithSelectedModel);
  });

  const availablePlcs = computed<EligibleHost[]>(() => {
    if (form.modbus_firmware_version_id === '')
      return [];

    const peripheralFwId = Number(form.modbus_firmware_version_id);

    return props.options.hosts.plcs.filter((p) => {
      if (!hostShareProtocolWithSelectedModel(p))
        return false;

      if (p.firmware_version_id === undefined)
        return false;

      const peripherals = props.options.compatibility[String(p.firmware_version_id)] || [];
      return peripherals.includes(peripheralFwId);
    });
  });

  watch(firmwareOptions, (opts) => {
    if (opts.length === 1)
      form.modbus_firmware_version_id = String(opts[0].id);
    else if (opts.length === 0)
      form.modbus_firmware_version_id = '';
    else {
      const latest = opts.find((o) => o.is_latest);
      form.modbus_firmware_version_id = latest ? String(latest.id) : '';
    }
  }, { immediate: true });

  watch(() => form.modbus_firmware_version_id, () => {
    form.host_kind = null;
    form.gateway_id = '';
    form.plc_id = '';
  });
  watch(() => form.model_id, () => {
    form.host_kind = null;
    form.gateway_id = '';
    form.plc_id = '';
  });

  function setHostKind(kind: HostKind) {
    form.host_kind = kind;
    if (kind === 'gateway')
      form.plc_id = '';
    else
      form.gateway_id = '';
  }

  const hostSelected = computed(() => {
    if (form.host_kind === 'gateway')
      return form.gateway_id !== '';

    if (form.host_kind === 'plc')
      return form.plc_id !== '';

    return false;
  });

  const namePlaceholder = computed(() => {
    return selectedModel.value?.display_type
      ? `e.g. ${selectedModel.value.display_type} — Chamber A`
      : 'e.g. Chamber A';
  });

  const canSubmit = computed(() => {
    if (form.model_id === '')
      return false;

    if (form.modbus_firmware_version_id === '')
      return false;

    if (!hostSelected.value)
      return false;

    if (!form.name.trim())
      return false;

    if (form.slave_id === null || form.slave_id < 1 || form.slave_id > 247)
      return false;

    if (form.host_kind === 'gateway' && !form.private_ip.trim())
      return false;

    return true;
  });

  async function submit() {
    if (!canSubmit.value)
      return;

    submitting.value = true;
    error.value = null;

    const payload: Record<string, unknown> = {
      name: form.name.trim(),
      slave_id: form.slave_id,
      model_id: Number(form.model_id),
      modbus_firmware_version_id: Number(form.modbus_firmware_version_id),
      active: true,
    };

    if (form.host_kind === 'gateway') {
      payload.gateway_id = Number(form.gateway_id);
      payload.private_ip = form.private_ip.trim();
    } else if (form.host_kind === 'plc')
      payload.plc_id = Number(form.plc_id);

    const result = await execute(
      () => axios.post(routePath('modbus_devices_create'), { modbus_device: payload }),
      { showSuccessToast: true, successMessage: 'Device added', showErrorToast: false }
    );

    submitting.value = false;
    if (result.success)
      emit('success');
    else
      error.value = result.error.error || 'Could not add device. Please try again.';
  }
</script>
