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
    client_setup: {
      new: true,
      edit: true,
      create: true,
      update: true,
      destroy: true
    },
    client_users: {
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
    segments: {
      index: true,
      create: true,
      update: true,
      destroy: true
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
      write: true,
      update: true
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
    client_setup: {
      new: true,
      edit: true,
      create: true,
      update: false,
      destroy: false
    },
    client_users: {
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
    segments: {
      index: true,
      create: false,
      update: false,
      destroy: false
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
      update: true
    },
    measurement_points: {
      write: true,
      update: true
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
    client_setup: {
      new: true,
      edit: true,
      create: true,
      update: false,
      destroy: false
    },
    client_users: {
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
    segments: {
      index: true,
      create: false,
      update: false,
      destroy: false
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
      write: false,
      update: false
    }
  }
};

function isActionKeyForController(
  controllerKey: keyof RoutePermissions,
  actionKey: string
): actionKey is keyof RoutePermissions[typeof controllerKey] {
  const sampleRole = Object.keys(PERMISSION_MATRIX)[0] as Role;
  const controllerPermissions = PERMISSION_MATRIX[sampleRole][controllerKey];
  return actionKey in controllerPermissions;
}

export default function usePermissions() {
  const { role } = useAuth();

  const permissions = computed(() => {
    if (!role.value)
      throw new Error('User role is not defined');

    return PERMISSION_MATRIX[role.value];
  });

  function canAccess(
    controller: keyof RoutePermissions,
    action: string
  ): boolean {
    if (!role.value)
      return false;

    if (!isActionKeyForController(controller, action))
      return false;

    return PERMISSION_MATRIX[role.value][controller]?.[action] === true;
  }

  return {
    permissions,
    canAccess
  };
}
