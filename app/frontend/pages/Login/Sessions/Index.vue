<template>
  <div class="container py-4">
    <CCard>
      <CCardHeader class="d-flex justify-content-between align-items-center">
        <h5 class="mb-0">Active sessions</h5>
        <CButton
          color="danger"
          variant="outline"
          size="sm"
          @click="revokeAll"
          :disabled="sessions.filter(s => !s.is_current_session).length === 0">
          Sign out everywhere else
        </CButton>
      </CCardHeader>

      <CCardBody>
        <CListGroup flush>
          <CListGroupItem
            v-for="session in sessions"
            :key="session.id"
            class="d-flex justify-content-between align-items-center">
            <div>
              <div class="d-flex align-items-center gap-2">
                <strong>{{ session.client_name }}</strong>
                <CBadge v-if="session.is_current_session" color="success">
                  This device
                </CBadge>
                <CBadge v-if="session.transport === 'mobile'" color="info">
                  Mobile
                </CBadge>
                <CBadge v-if="session.remembered" color="secondary">
                  Remembered
                </CBadge>
              </div>
              <div class="text-muted small mt-1">
                {{ session.ip_address }} · last active {{ formatRelative(session.last_seen_at) }}
              </div>
            </div>
            <CButton
              color="danger"
              variant="ghost"
              size="sm"
              @click="revoke(session)">
              {{ session.is_current_session ? 'Sign out' : 'Revoke' }}
            </CButton>
          </CListGroupItem>
        </CListGroup>
      </CCardBody>
    </CCard>
  </div>
</template>

<script setup lang="ts">
  import { router } from '@inertiajs/vue3';
  import { usePage } from '@inertiajs/vue3';
  import useAuth from '@/composables/useAuth';

  type Session = {
    id: number;
    transport: 'web' | 'mobile';
    client_name: string;
    ip_address: string;
    last_seen_at: string;
    expires_at: string;
    is_current_session: boolean;
    remembered: boolean;
  }

  const { paths } = useAuth();
  const page = usePage<{
    sessions: Session[];
  }>();
  const sessions = page.props.sessions;

  function formatRelative(iso: string) {
    const date = new Date(iso);
    const seconds = Math.floor((Date.now() - date.getTime()) / 1000);

    if (seconds < 60)
      return 'just now';

    if (seconds < 3600)
      return `${Math.floor(seconds / 60)}m ago`;

    if (seconds < 86400)
      return `${Math.floor(seconds / 3600)}h ago`;

    return `${Math.floor(seconds / 86400)}d ago`;
  }

  function revoke(session: Session) {
    const message = session.is_current_session
      ? 'Sign out of this session?'
      : `Sign out ${session.client_name}?`

    if (!confirm(message))
      return;

    router.delete(paths.value.actions.deleteSession(session.id));
  }

  function revokeAll() {
    if (!confirm('Sign out of all other sessions? This cannot be undone.'))
      return;

    router.delete(paths.value.actions.deleteAllSessions);
  }
</script>
