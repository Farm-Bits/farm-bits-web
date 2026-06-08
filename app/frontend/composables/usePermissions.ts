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
    sessions: {
      destroy_all: true,
      destroy: true
    },
    two_factors: {
      update: true
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
    devices: {
      index: true
    },
    gateways: {
      update: true
    },
    plcs: {
      refresh_interfaces: true,
      show: true,
      update: true
    },
    modbus_devices: {
      refresh_values: true,
      create: true,
      show: true,
      update: true,
      destroy: true
    },
    measurement_points: {
      bulk_write: true,
      write: true,
      operation_mode_config: true,
      update: true
    },
    alerts: {
      index: true,
      show: true
    },
    alert_rules: {
      index: true,
      create: true,
      new: true,
      edit: true,
      update: true,
      destroy: true
    },
    alert_subscriptions: {
      index: true,
      create: true,
      update: true,
      destroy: true
    },
    analytics: {
      show: true,
      hourly: true,
      raw: true,
      weather_hourly: true,
      weather_raw: true
    },
    programs: {
      index: true,
      show_plc: true,
      show_modbus_device: true,
      refresh_modbus_device: true
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
    sessions: {
      destroy_all: true,
      destroy: true
    },
    two_factors: {
      update: true
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
    devices: {
      index: true
    },
    gateways: {
      update: true
    },
    plcs: {
      refresh_interfaces: true,
      show: true,
      update: true
    },
    modbus_devices: {
      refresh_values: true,
      create: true,
      show: true,
      update: true,
      destroy: true
    },
    measurement_points: {
      bulk_write: true,
      write: true,
      operation_mode_config: true,
      update: true
    },
    alerts: {
      index: true,
      show: true
    },
    alert_rules: {
      index: true,
      create: true,
      new: true,
      edit: true,
      update: true,
      destroy: true
    },
    alert_subscriptions: {
      index: true,
      create: true,
      update: true,
      destroy: true
    },
    analytics: {
      show: true,
      hourly: true,
      raw: true,
      weather_hourly: true,
      weather_raw: true
    },
    programs: {
      index: true,
      show_plc: true,
      show_modbus_device: true,
      refresh_modbus_device: true
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
    sessions: {
      destroy_all: true,
      destroy: true
    },
    two_factors: {
      update: true
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
    devices: {
      index: true
    },
    gateways: {
      update: false
    },
    plcs: {
      refresh_interfaces: true,
      show: true,
      update: false
    },
    modbus_devices: {
      refresh_values: true,
      create: false,
      show: true,
      update: false,
      destroy: false
    },
    measurement_points: {
      bulk_write: true,
      write: true,
      operation_mode_config: true,
      update: false
    },
    alerts: {
      index: true,
      show: true
    },
    alert_rules: {
      index: true,
      create: true,
      new: true,
      edit: true,
      update: true,
      destroy: true
    },
    alert_subscriptions: {
      index: true,
      create: true,
      update: true,
      destroy: true
    },
    analytics: {
      show: true,
      hourly: true,
      raw: true,
      weather_hourly: true,
      weather_raw: true
    },
    programs: {
      index: true,
      show_plc: true,
      show_modbus_device: true,
      refresh_modbus_device: true
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
    sessions: {
      destroy_all: true,
      destroy: true
    },
    two_factors: {
      update: true
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
    devices: {
      index: true
    },
    gateways: {
      update: false
    },
    plcs: {
      refresh_interfaces: false,
      show: true,
      update: false
    },
    modbus_devices: {
      refresh_values: false,
      create: false,
      show: true,
      update: false,
      destroy: false
    },
    measurement_points: {
      bulk_write: false,
      write: false,
      operation_mode_config: true,
      update: false
    },
    alerts: {
      index: true,
      show: true
    },
    alert_rules: {
      index: true,
      create: true,
      new: true,
      edit: true,
      update: true,
      destroy: true
    },
    alert_subscriptions: {
      index: true,
      create: true,
      update: true,
      destroy: true
    },
    analytics: {
      show: true,
      hourly: true,
      raw: true,
      weather_hourly: true,
      weather_raw: true
    },
    programs: {
      index: true,
      show_plc: true,
      show_modbus_device: true,
      refresh_modbus_device: false
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
