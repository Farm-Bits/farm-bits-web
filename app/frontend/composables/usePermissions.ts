import { computed } from 'vue';
import useAuth from '@/composables/useAuth';
import type { Role, RoutePermissions } from '../types/permissions';

const PERMISSION_MATRIX: Record<Role, RoutePermissions> = {
  admin: {
    live: {
      show: true,
      poll: true,
      poll_weather: true
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
    gateways: {
      index: true,
      update: true,
      destroy: true
    },
    plcs: {
      refresh_interfaces: true,
      show: true,
      update: true
    },
    measurement_points: {
      write: true,
      operation_mode_config: true,
      update: true
    },
    analytics: {
      show: true,
      hourly: true,
      raw: true,
      weather_hourly: true,
      weather_raw: true
    },
    dashboard: {
      show: true
    }
  },
  site_admin: {
    live: {
      show: true,
      poll: true,
      poll_weather: true
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
    gateways: {
      index: true,
      update: true,
      destroy: true
    },
    plcs: {
      refresh_interfaces: true,
      show: true,
      update: true
    },
    measurement_points: {
      write: true,
      operation_mode_config: true,
      update: true
    },
    analytics: {
      show: true,
      hourly: true,
      raw: true,
      weather_hourly: true,
      weather_raw: true
    },
    dashboard: {
      show: true
    }
  },
  manager: {
    live: {
      show: true,
      poll: true,
      poll_weather: true
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
    gateways: {
      index: true,
      update: false,
      destroy: false
    },
    plcs: {
      refresh_interfaces: true,
      show: true,
      update: false
    },
    measurement_points: {
      write: true,
      operation_mode_config: true,
      update: false
    },
    analytics: {
      show: true,
      hourly: true,
      raw: true,
      weather_hourly: true,
      weather_raw: true
    },
    dashboard: {
      show: true
    }
  },
  viewer: {
    live: {
      show: true,
      poll: true,
      poll_weather: true
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
    gateways: {
      index: true,
      update: false,
      destroy: false
    },
    plcs: {
      refresh_interfaces: true,
      show: true,
      update: false
    },
    measurement_points: {
      write: false,
      operation_mode_config: true,
      update: false
    },
    analytics: {
      show: true,
      hourly: true,
      raw: true,
      weather_hourly: true,
      weather_raw: true
    },
    dashboard: {
      show: true
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
