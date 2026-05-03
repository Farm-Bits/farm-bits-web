<template>
  <CContainer fluid class="py-3">
    <div class="d-flex align-items-center mb-3">
      <Link :href="ROUTES.alert_rules_index.path" class="btn btn-link p-0 me-3">
        <CIcon name="cilArrowLeft" />
      </Link>
      <h1 class="h3 mb-0">Edit Alert Rule</h1>
    </div>

    <CCard>
      <CCardBody>
        <AlertRuleForm
          :initial-rule="alertRule"
          :measurement-points="measurementPoints"
          submit-label="Save Changes"
          @submit="handleSubmit"
          @cancel="goBack" />
      </CCardBody>
    </CCard>
  </CContainer>
</template>

<script lang="ts" setup>
  import { Link, router } from '@inertiajs/vue3';
  import axios from 'axios';
  import AlertRuleForm from './AlertRuleForm.vue';
  import { ROUTES } from '@/types/permissions';
  import type { MeasurementPointOption, AlertRule } from '@/types/alerts';

  const props = defineProps<{
    alertRule: AlertRule;
    measurementPoints: MeasurementPointOption[];
  }>();

  async function handleSubmit(payload: Partial<AlertRule>): Promise<void> {
    try {
      const url = ROUTES.alert_rules_update.path.replace(':id', String(props.alertRule.id));
      await axios.patch(url, { alert_rule: payload });
      router.visit(ROUTES.alert_rules_index.path);
    } catch (err: any) {
      const message = err?.response?.data?.error ?? 'Failed to update rule.';
      window.alert(message);
    }
  }

  function goBack(): void {
    router.visit(ROUTES.alert_rules_index.path);
  }
</script>
