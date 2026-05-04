<template>
  <CContainer fluid class="py-3">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h1 class="h3 mb-0">Alerts</h1>
      <CBadge :color="activeBadgeColor" class="px-3 py-2">
        {{ activeAlerts.length }} active
      </CBadge>
      <div class="d-flex gap-2">
        <CButton
          color="primary"
          @click="router.visit(ROUTES.alert_rules_index.path)">
          <CIcon icon="cilPlus" class="me-2" />
          Alert Rules
        </CButton>
      </div>
    </div>

    <CCard>
      <CCardBody class="p-0">
        <CNav variant="tabs" class="px-3 pt-2">
          <CNavItem>
            <CNavLink
              :active="currentTab === 'active'"
              @click="currentTab = 'active'"
              role="button">
              Active
              <CBadge v-if="activeAlerts.length > 0" color="danger" class="ms-2">
                {{ activeAlerts.length }}
              </CBadge>
            </CNavLink>
          </CNavItem>

          <CNavItem>
            <CNavLink
              :active="currentTab === 'history'"
              @click="currentTab = 'history'"
              role="button">
              History
              <CBadge v-if="closedAlerts.length > 0" color="secondary" class="ms-2">
                {{ closedAlerts.length }}
              </CBadge>
            </CNavLink>
          </CNavItem>
        </CNav>

        <div v-if="visibleAlerts.length === 0" class="text-center py-5 text-muted">
          <CIcon name="cilCheckCircle" size="xl" class="mb-2 text-success" />
          <p class="mb-0">
            {{ currentTab === 'active' ? 'No active alerts.' : 'No alerts in history.' }}
          </p>
        </div>

        <CTable v-else hover responsive class="mb-0">
          <CTableHead>
            <CTableRow>
              <CTableHeaderCell style="width: 110px;">Severity</CTableHeaderCell>
              <CTableHeaderCell>Rule</CTableHeaderCell>
              <CTableHeaderCell>Measurement Point</CTableHeaderCell>
              <CTableHeaderCell>Site</CTableHeaderCell>
              <CTableHeaderCell>Condition</CTableHeaderCell>
              <CTableHeaderCell>Started</CTableHeaderCell>
              <CTableHeaderCell>{{ currentTab === 'active' ? 'Open for' : 'Duration' }}</CTableHeaderCell>
            </CTableRow>
          </CTableHead>

          <CTableBody>
            <CTableRow
              v-for="alert in visibleAlerts"
              :key="alert.id"
              @click="openAlert(alert)"
              class="alert-row"
              :class="rowClass(alert)">
              <CTableDataCell>
                <CBadge :color="severityColor(alert.severity)">
                  {{ alert.severity.toUpperCase() }}
                </CBadge>
              </CTableDataCell>

              <CTableDataCell>
                <strong>{{ alert.rule_name }}</strong>
              </CTableDataCell>

              <CTableDataCell>{{ alert.measurement_point_name }}</CTableDataCell>

              <CTableDataCell>{{ alert.segment_name }}</CTableDataCell>

              <CTableDataCell>
                <span class="text-muted small">{{ conditionSummary(alert) }}</span>
              </CTableDataCell>

              <CTableDataCell>
                <span :title="formatAbsoluteTime(alert.started_at)">
                  {{ formatRelativeTime(alert.started_at) }}
                </span>
              </CTableDataCell>

              <CTableDataCell>
                <strong v-if="alert.open" class="text-danger">
                  {{ formatDuration(liveDuration(alert)) }}
                </strong>
                <span v-else class="text-muted">
                  {{ formatDuration(alert.duration_seconds) }}
                </span>
              </CTableDataCell>
            </CTableRow>
          </CTableBody>
        </CTable>
      </CCardBody>
    </CCard>
  </CContainer>
</template>

<script lang="ts" setup>
  import { computed, ref, onMounted, onBeforeUnmount } from 'vue';
  import { router } from '@inertiajs/vue3';
  import { ROUTES } from '@/types/permissions';
  import {
    formatRelativeTime,
    formatAbsoluteTime,
    formatDuration,
    severityColor,
    conditionSummary
  } from '@/utils/alertFormatters';
  import type { Alert, AlertSeverity } from '@/types/alerts';

  const props = defineProps<{
    alerts: Alert[];
  }>();

  const currentTab = ref<'active' | 'history'>('active');

  // Tick once per second; used as a reactivity dependency for liveDuration
  // so open-alert "Open for" counters tick without re-fetching.
  const now = ref(Date.now());
  let tickInterval: ReturnType<typeof setInterval> | undefined;

  onMounted(() => {
    tickInterval = setInterval(() => {
      now.value = Date.now();
    }, 1000);
  });

  onBeforeUnmount(() => {
    if (tickInterval) {
      clearInterval(tickInterval);
    }
  });

  const activeAlerts = computed<Alert[]>(() => {
    return props.alerts.filter(a => a.open);
  });

  const closedAlerts = computed<Alert[]>(() => {
    return props.alerts.filter(a => !a.open);
  });

  const visibleAlerts = computed<Alert[]>(() => {
    return currentTab.value === 'active' ? activeAlerts.value : closedAlerts.value;
  });

  const activeBadgeColor = computed<string>(() => {
    if (activeAlerts.value.length === 0) {
      return 'success';
    }

    const hasCritical = activeAlerts.value.some(a => a.severity === 'critical');
    if (hasCritical) {
      return 'danger';
    }

    const hasWarning = activeAlerts.value.some(a => a.severity === 'warning');
    if (hasWarning) {
      return 'warning';
    }

    return 'info';
  });

  function liveDuration(alert: Alert): number {
    const startedMs = new Date(alert.started_at).getTime();
    return Math.floor((now.value - startedMs) / 1000);
  }

  function rowClass(alert: Alert): string[] {
    if (!alert.open) {
      return [];
    }

    return [`alert-row--${alert.severity}`];
  }

  function openAlert(alert: Alert): void {
    // router.get(ROUTES.alerts_show.path(alert.id));
  }
</script>

<style scoped>
  .alert-row {
    cursor: pointer;
  }

  .alert-row--info {
    background-color: rgba(13, 202, 240, 0.05);
  }

  .alert-row--warning {
    background-color: rgba(255, 193, 7, 0.08);
  }

  .alert-row--critical {
    background-color: rgba(220, 53, 69, 0.10);
  }

  .alert-row--critical:hover,
  .alert-row--warning:hover,
  .alert-row--info:hover {
    filter: brightness(0.97);
  }
</style>
