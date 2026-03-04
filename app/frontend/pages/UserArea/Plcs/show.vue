<template>
  <CContainer fluid class="px-4 py-4">
    <!-- Header with Breadcrumb -->
    <CRow class="mb-3">
      <div>
        <nav aria-label="breadcrumb">
          <ol class="breadcrumb mb-2">
            <li class="breadcrumb-item">
              <Link :href="ROUTES.gateways_index.path">Gateways & Controllers</Link>
            </li>
            <li class="breadcrumb-item active">{{ plc.name }}</li>
          </ol>
        </nav>
        <h1 class="h3 mb-1">Controller Configuration</h1>
        <p class="text-muted mb-0">
          Configure interfaces and measurement points for <strong>{{ plc.name }}</strong>
        </p>
      </div>
    </CRow>

    <!-- PLC Info Card -->
    <CCard class="mb-4 shadow-sm">
      <CCardBody>
        <div class="row g-4">
          <div class="col-md-3">
            <div class="d-flex align-items-center">
              <CIcon icon="cilMemory" size="xl" class="text-primary me-3" />
              <div>
                <div class="text-muted small">Controller</div>
                <div class="fw-semibold">{{ plc.name }}</div>
                <div class="text-muted small">{{ plc.label }}</div>
              </div>
            </div>
          </div>
          <div class="col-md-2">
            <div class="text-muted small">Version</div>
            <div class="fw-semibold">{{ plc.plc_version.name }}</div>
          </div>
          <div class="col-md-2">
            <div class="text-muted small">Slave ID</div>
            <div class="fw-semibold">{{ plc.slave_id }}</div>
          </div>
          <div class="col-md-2">
            <div class="text-muted small">IP Address</div>
            <div class="fw-semibold font-monospace">{{ plc.private_ip || 'N/A' }}</div>
          </div>
          <div class="col-md-3">
            <div class="text-muted small">Last Seen</div>
            <div class="fw-semibold">
              {{ plc.last_seen_at ? formatDate(plc.last_seen_at) : 'Never' }}
            </div>
          </div>
        </div>
      </CCardBody>
    </CCard>

    <CTabs v-model:active-item-key="activeTab" variant="tabs">
      <CTabList variant="tabs">
        <CTab
          v-for="tab in COMMUNICATION_TYPE_TABS"
          :key="tab.key"
          :item-key="tab.key"
          class="tab-item">
          <CIcon :name="tab.icon" class="me-2" />
          {{ tab.label }}
          <CBadge color="primary" shape="rounded-pill" class="ms-1">
            {{ getInterfaceCount(tab.key) }}
          </CBadge>
        </CTab>
        <CTab item-key="configuration" class="tab-item">
          <CIcon icon="cilSettings" />
          Configuration
        </CTab>
      </CTabList>

      <CTabContent>
        <CTabPanel
          v-for="tab in COMMUNICATION_TYPE_TABS"
          :key="tab.key"
          :item-key="tab.key">
        <InterfaceList
          :plcName="plc.name"
          :interfaces="getInterfacesByType(tab.key)"
          :communicationType="tab.key"
          :segments="segments"
          :measurementSubtypes="measurementSubtypes"
          @update-interface="handleUpdateInterface" />
        </CTabPanel>
        <CTabPanel item-key="configuration">
          <ConfigurationPanel :plc="plc" />
        </CTabPanel>
      </CTabContent>
    </CTabs>
  </CContainer>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import InterfaceList from './components/InterfaceList.vue';
  import ConfigurationPanel from './components/ConfigurationPanel.vue';
  import useAuth from '@/composables/useAuth';
  import usePermissions from '@/composables/usePermissions';
  import { ROUTES } from '@/types/permissions';
  import type { Segment } from '@/types/location';
  import type { CommunicationType, PlcWithInterfaces } from '@/types/plc';
  import type { MeasurementPoint, MeasurementSubtype } from '@/types/measurementPoint';
  import { COMMUNICATION_TYPE_TABS } from './types';

  const { currentSite, pageProps } = useAuth<{
    plc: PlcWithInterfaces;
    segments: Segment[];
    measurementSubtypes: MeasurementSubtype[];
  }>();
  const segments = currentSite.value?.segments || [];
  const { plc, measurementSubtypes } = pageProps.value;

  const activeTab = ref<CommunicationType>('digital_input');

  function getInterfacesByType(type: CommunicationType) {
    return plc.interfaces.filter((i) => i.communication_type === type);
  }

  function getInterfaceCount(type: CommunicationType) {
    return getInterfacesByType(type).length;
  }

  function formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleString();
  }

  async function handleUpdateInterface(
    updatedMeasurementPoint: MeasurementPoint,
    siblingMeasurementPoints: MeasurementPoint[]
  ) {
    const pointsMap = new Map<MeasurementPoint['id'], MeasurementPoint>(
      [updatedMeasurementPoint, ...siblingMeasurementPoints].map((p) => [p.id, p])
    );

    let remaining = pointsMap.size;
    for (const iface of plc.interfaces) {
      for (const mapping of iface.register_mappings) {
        const updatedPoint = pointsMap.get(mapping.measurement_point.id);
        if (updatedPoint) {
          mapping.measurement_point = updatedPoint;
          if (--remaining === 0)
            return;
        }
      }
    }
  }
</script>

<style scoped>
  .nav-link {
    cursor: pointer;
  }
</style>
