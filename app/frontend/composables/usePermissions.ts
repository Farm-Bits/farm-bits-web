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
    users: {
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
      create: true,
      update: true,
      destroy: true
    },
    protocols: {
      index: true,
      create: true,
      new: true,
      edit: true,
      show: true,
      update: true,
      destroy: true
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
    users: {
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
      create: false,
      update: false,
      destroy: false
    },
    protocols: {
      index: false,
      create: false,
      new: false,
      edit: false,
      show: false,
      update: false,
      destroy: false
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
    users: {
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
      create: false,
      update: false,
      destroy: false
    },
    protocols: {
      index: false,
      create: false,
      new: false,
      edit: false,
      show: false,
      update: false,
      destroy: false
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
    permissions
  };
}
