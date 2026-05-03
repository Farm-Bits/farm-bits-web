<template>
  <CContainer fluid class="py-3">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h1 class="h3 mb-0">Alert Rules</h1>

      <Link
        v-if="permissions?.alert_rules.new"
        :href="ROUTES.alert_rules_new.path"
        class="btn btn-primary">
        <CIcon name="cilPlus" class="me-1" />
        New Rule
      </Link>
    </div>

    <CCard>
      <CCardBody class="p-0">
        <div v-if="alertRules.length === 0" class="text-center py-5 text-muted">
          <CIcon name="cilTask" size="xl" class="mb-2" />
          <p class="mb-0">No alert rules defined yet.</p>
          <Link
            v-if="permissions?.alert_rules.new"
            :href="ROUTES.alert_rules_new.path"
            class="btn btn-link">
            Create your first rule
          </Link>
        </div>

        <CTable v-else hover responsive class="mb-0">
          <CTableHead>
            <CTableRow>
              <CTableHeaderCell style="width: 40px;"></CTableHeaderCell>
              <CTableHeaderCell style="width: 110px;">Severity</CTableHeaderCell>
              <CTableHeaderCell>Name</CTableHeaderCell>
              <CTableHeaderCell>Measurement Point</CTableHeaderCell>
              <CTableHeaderCell>Segment</CTableHeaderCell>
              <CTableHeaderCell>Condition</CTableHeaderCell>
              <CTableHeaderCell>Dwell</CTableHeaderCell>
              <CTableHeaderCell v-if="permissions?.alert_rules.edit" style="width: 120px;"></CTableHeaderCell>
            </CTableRow>
          </CTableHead>

          <CTableBody>
            <CTableRow
              v-for="rule in alertRules"
              :key="rule.id"
              :class="rule.active ? '' : 'rule-row--inactive'">
              <CTableDataCell>
                <CFormSwitch
                  v-if="permissions?.alert_rules.update"
                  :model-value="rule.active"
                  @change="toggleActive(rule)"
                  :disabled="togglingIds.has(rule.id)" />
                <CIcon
                  v-else
                  :name="rule.active ? 'cilCheckCircle' : 'cilXCircle'"
                  :class="rule.active ? 'text-success' : 'text-muted'" />
              </CTableDataCell>

              <CTableDataCell>
                <CBadge :color="severityColor(rule.severity)">
                  {{ rule.severity.toUpperCase() }}
                </CBadge>
              </CTableDataCell>

              <CTableDataCell>
                <strong>{{ rule.name }}</strong>
              </CTableDataCell>

              <CTableDataCell>{{ rule.measurement_point_name || '—' }}</CTableDataCell>

              <CTableDataCell>{{ rule.segment_name || '—' }}</CTableDataCell>

              <CTableDataCell>
                <span class="text-muted small">{{ conditionSummary(rule) }}</span>
              </CTableDataCell>

              <CTableDataCell>
                <span v-if="rule.min_duration_seconds && rule.min_duration_seconds > 0" class="text-muted small">
                  {{ formatDuration(rule.min_duration_seconds) }}
                </span>
                <span v-else class="text-muted small">—</span>
              </CTableDataCell>

              <CTableDataCell v-if="permissions?.alert_rules.edit">
                <Link
                  :href="ROUTES.alert_rules_edit.path.replace(':id', String(rule.id))"
                  class="btn btn-sm btn-outline-secondary me-1">
                  <CIcon name="cilPencil" size="sm" />
                </Link>
                <CButton
                  color="danger"
                  variant="outline"
                  size="sm"
                  @click="confirmDestroy(rule)"
                  :disabled="destroyingIds.has(rule.id)">
                  <CIcon name="cilTrash" size="sm" />
                </CButton>
              </CTableDataCell>
            </CTableRow>
          </CTableBody>
        </CTable>
      </CCardBody>
    </CCard>
  </CContainer>

  <CModal :visible="!!ruleToDestroy" @close="ruleToDestroy = null" alignment="center">
    <CModalHeader>
      <CModalTitle>Delete Alert Rule</CModalTitle>
    </CModalHeader>
    <CModalBody>
      <p class="mb-2">
        Are you sure you want to delete
        <strong>{{ ruleToDestroy?.name }}</strong>?
      </p>
      <p class="text-muted small mb-0">
        Existing alerts fired by this rule will keep their snapshot fields and remain in the alert history.
      </p>
    </CModalBody>
    <CModalFooter>
      <CButton color="secondary" variant="outline" @click="ruleToDestroy = null">
        Cancel
      </CButton>
      <CButton color="danger" @click="performDestroy">
        Delete
      </CButton>
    </CModalFooter>
  </CModal>
</template>

<script lang="ts" setup>
  import { ref, reactive } from 'vue';
  import { Link, router } from '@inertiajs/vue3';
  import axios from 'axios';
  import usePermissions from '@/composables/usePermissions';
  import { ROUTES } from '@/types/permissions';
  import {
    severityColor,
    conditionSummary,
    formatDuration
  } from '@/utils/alertFormatters';
  import type { AlertRule } from '@/types/alerts';

  const props = defineProps<{
    alertRules: AlertRule[];
  }>();

  const { permissions } = usePermissions();

  const togglingIds = reactive(new Set<number>());
  const destroyingIds = reactive(new Set<number>());
  const ruleToDestroy = ref<AlertRule | null>(null);

  async function toggleActive(rule: AlertRule): Promise<void> {
    if (togglingIds.has(rule.id)) {
      return;
    }
    togglingIds.add(rule.id);

    try {
      await axios.patch(ROUTES.alert_rules_update.path.replace(':id', String(rule.id)), {
        alert_rule: { active: !rule.active }
      });
      router.reload({ only: ['alertRules'] });
    } catch (err: any) {
      const message = err?.response?.data?.error ?? 'Failed to update rule.';
      window.alert(message);
    } finally {
      togglingIds.delete(rule.id);
    }
  }

  function confirmDestroy(rule: AlertRule): void {
    ruleToDestroy.value = rule;
  }

  async function performDestroy(): Promise<void> {
    const rule = ruleToDestroy.value;
    if (!rule || destroyingIds.has(rule.id)) {
      return;
    }
    destroyingIds.add(rule.id);

    try {
      const url = ROUTES.alert_rules_destroy.path.replace(':id', String(rule.id));
      await axios.delete(url);
      ruleToDestroy.value = null;
      router.reload({ only: ['alertRules'] });
    } catch (err: any) {
      const message = err?.response?.data?.error ?? 'Failed to delete rule.';
      window.alert(message);
    } finally {
      destroyingIds.delete(rule.id);
    }
  }
</script>

<style scoped>
  .rule-row--inactive {
    opacity: 0.55;
  }
</style>
