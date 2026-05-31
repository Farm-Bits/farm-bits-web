<template>
  <CContainer fluid class="py-3">
    <div class="d-flex align-items-center mb-3">
      <Link :href="routePath('alert_rules_index')" class="btn btn-link p-0 me-3">
        <CIcon name="cilArrowLeft" />
      </Link>
      <h1 class="h3 mb-0">New Alert Rule</h1>
    </div>

    <CCard>
      <CCardBody>
        <AlertRuleForm
          :initial-rule="null"
          :measurement-points="measurementPoints"
          submit-label="Create Rule"
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
  import useAuth from '@/composables/useAuth';
  import type { MeasurementPointOption, AlertRule } from '@/types/alerts';

  defineProps<{
    measurementPoints: MeasurementPointOption[];
  }>();

  const { routePath } = useAuth();

  async function handleSubmit(payload: Partial<AlertRule>): Promise<void> {
    try {
      await axios.post(routePath('alert_rules_create'), { alert_rule: payload });
      router.visit(routePath('alert_rules_index'));
    } catch (err: any) {
      const message = err?.response?.data?.error ?? 'Failed to create rule.';
      window.alert(message);
    }
  }

  function goBack(): void {
    router.visit(routePath('alert_rules_index'));
  }
</script>
