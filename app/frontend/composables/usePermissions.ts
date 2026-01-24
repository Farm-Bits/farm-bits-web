import { computed } from 'vue';
import useAuth from '@/composables/useAuth';
import type { Role, RoutePermissions } from '../types/permissions';

const PERMISSION_MATRIX: Record<Role, RoutePermissions> = {
  admin: {
    dashboard: {
      show: true
    },
    my_account: {
      show: true,
      update: true,
      destroy: true
    },
    company_setup: {
      new: true,
      edit: true,
      create: true,
      update: true,
      destroy: true
    },
    company_users: {
      index: true,
      update: true,
      destroy: true
    },
    invitations: {
      index: true,
      create: true,
      destroy: true,
      resend: true
    },
    sites: {
      index: true,
      show: true,
      create: true,
      update: true,
      destroy: true
    },
    terminals: {
      index: true,
      update: true,
      destroy: true
    },
    plcs: {
      show: true,
      update: true
    },
    measurement_points: {
      update: true,
      write: true
    }
  },
  site_admin: {
    dashboard: {
      show: true
    },
    my_account: {
      show: true,
      update: true,
      destroy: true
    },
    company_setup: {
      new: true,
      edit: true,
      create: true,
      update: false,
      destroy: false
    },
    company_users: {
      index: true,
      update: true,
      destroy: true
    },
    invitations: {
      index: true,
      create: true,
      destroy: true,
      resend: true
    },
    sites: {
      index: true,
      show: true,
      create: false,
      update: true,
      destroy: false
    },
    terminals: {
      index: true,
      update: true,
      destroy: true
    },
    plcs: {
      show: true,
      update: true
    },
    measurement_points: {
      update: true,
      write: true
    }
  },
  manager: {
    dashboard: {
      show: true
    },
    my_account: {
      show: true,
      update: true,
      destroy: true
    },
    company_setup: {
      new: true,
      edit: true,
      create: true,
      update: false,
      destroy: false
    },
    company_users: {
      index: true,
      update: false,
      destroy: false
    },
    invitations: {
      index: false,
      create: false,
      destroy: false,
      resend: false
    },
    sites: {
      index: false,
      show: false,
      create: false,
      update: false,
      destroy: false
    },
    terminals: {
      index: true,
      update: false,
      destroy: false
    },
    plcs: {
      show: true,
      update: false
    },
    measurement_points: {
      update: false,
      write: true
    }
  },
  viewer: {
    dashboard: {
      show: true
    },
    my_account: {
      show: true,
      update: true,
      destroy: true
    },
    company_setup: {
      new: true,
      edit: false,
      create: true,
      update: false,
      destroy: false
    },
    company_users: {
      index: true,
      update: false,
      destroy: false
    },
    invitations: {
      index: false,
      create: false,
      destroy: false,
      resend: false
    },
    sites: {
      index: false,
      show: false,
      create: false,
      update: false,
      destroy: false
    },
    terminals: {
      index: true,
      update: false,
      destroy: false
    },
    plcs: {
      show: true,
      update: false
    },
    measurement_points: {
      update: false,
      write: false
    }
  }
};

export default function usePermissions() {
  const { currentRole } = useAuth();

  const permissions = computed(() => {
    if (!currentRole.value)
      return null;

    return PERMISSION_MATRIX[currentRole.value];
  });

  return {
    permissions
  };
}
