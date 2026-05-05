// Auto-generated file - Do not edit manually
// Generated at: 2026-05-05 18:12:59 UTC

import type { Method } from '@inertiajs/core';

// Available roles from Roleable
export type Role = 'admin' | 'site_admin' | 'manager' | 'viewer';

export const ROLES: Record<Role, { name: string; description: string; level: number; siteSpecific: boolean }> = {
  admin: {
    name: 'Admin',
    description: 'Full access to all sites, management of company settings',
    level: 5,
    siteSpecific: false
  },
  site_admin: {
    name: 'Site Admin',
    description: 'Full access on assigned sites',
    level: 4,
    siteSpecific: true
  },
  manager: {
    name: 'Manager',
    description: 'Control on assigned sites',
    level: 3,
    siteSpecific: true
  },
  viewer: {
    name: 'Viewer',
    description: 'Assigned sites, read-only',
    level: 2,
    siteSpecific: true
  }
} as const;

// Valid controller keys
export type ControllerKey = 'live' | 'my_account' | 'sessions' | 'two_factors' | 'company_setup' | 'company_users' | 'invitations' | 'sites' | 'devices' | 'gateways' | 'plcs' | 'modbus_devices' | 'measurement_points' | 'alerts' | 'alert_rules' | 'alert_subscriptions' | 'analytics' | 'programs' | 'dashboard';

// Route permissions mapping
export type RoutePermissions = {
  live: {
    show: boolean;
    poll: boolean;
    poll_weather: boolean;
  };
  my_account: {
    show: boolean;
    update: boolean;
    destroy: boolean;
  };
  sessions: {
    destroy_all: boolean;
    destroy: boolean;
  };
  two_factors: {
    update: boolean;
  };
  company_setup: {
    new: boolean;
    edit: boolean;
    create: boolean;
    update: boolean;
    destroy: boolean;
  };
  company_users: {
    index: boolean;
    update: boolean;
    destroy: boolean;
  };
  invitations: {
    index: boolean;
    create: boolean;
    destroy: boolean;
    resend: boolean;
  };
  sites: {
    index: boolean;
    create: boolean;
    show: boolean;
    update: boolean;
    destroy: boolean;
  };
  devices: {
    index: boolean;
  };
  gateways: {
    update: boolean;
  };
  plcs: {
    refresh_interfaces: boolean;
    show: boolean;
    update: boolean;
  };
  modbus_devices: {
    refresh_values: boolean;
    create: boolean;
    show: boolean;
    update: boolean;
    destroy: boolean;
  };
  measurement_points: {
    bulk_write: boolean;
    write: boolean;
    operation_mode_config: boolean;
    update: boolean;
  };
  alerts: {
    index: boolean;
    show: boolean;
  };
  alert_rules: {
    index: boolean;
    create: boolean;
    new: boolean;
    edit: boolean;
    update: boolean;
    destroy: boolean;
  };
  alert_subscriptions: {
    index: boolean;
    create: boolean;
    update: boolean;
    destroy: boolean;
  };
  analytics: {
    show: boolean;
    hourly: boolean;
    raw: boolean;
    weather_hourly: boolean;
    weather_raw: boolean;
  };
  programs: {
    index: boolean;
    show_plc: boolean;
    show_modbus_device: boolean;
  };
  dashboard: {
    show: boolean;
  };
};

// Complete permission context
export type PermissionContext = {
  role: Role;
  routePermissions: RoutePermissions;
};

// Route information
export type RouteInfo = {
  controller: string;
  action: string;
  path: string;
  verb: Method;
};

export const ROUTES: Record<string, RouteInfo> = {
  live_show: {
    controller: 'live',
    action: 'show',
    path: '/user',
    verb: 'get'
  },
  my_account_show: {
    controller: 'my_account',
    action: 'show',
    path: '/user/my_account',
    verb: 'get'
  },
  my_account_update: {
    controller: 'my_account',
    action: 'update',
    path: '/user/my_account',
    verb: 'put'
  },
  my_account_destroy: {
    controller: 'my_account',
    action: 'destroy',
    path: '/user/my_account',
    verb: 'delete'
  },
  sessions_destroy_all: {
    controller: 'sessions',
    action: 'destroy_all',
    path: '/user/sessions',
    verb: 'delete'
  },
  sessions_destroy: {
    controller: 'sessions',
    action: 'destroy',
    path: '/user/sessions/:id',
    verb: 'delete'
  },
  two_factors_update: {
    controller: 'two_factors',
    action: 'update',
    path: '/user/two_factors',
    verb: 'patch'
  },
  company_setup_new: {
    controller: 'company_setup',
    action: 'new',
    path: '/user/company_setup/new',
    verb: 'get'
  },
  company_setup_edit: {
    controller: 'company_setup',
    action: 'edit',
    path: '/user/company_setup/edit',
    verb: 'get'
  },
  company_setup_create: {
    controller: 'company_setup',
    action: 'create',
    path: '/user/company_setup',
    verb: 'post'
  },
  company_setup_update: {
    controller: 'company_setup',
    action: 'update',
    path: '/user/company_setup',
    verb: 'put'
  },
  company_setup_destroy: {
    controller: 'company_setup',
    action: 'destroy',
    path: '/user/company_setup',
    verb: 'delete'
  },
  company_users_index: {
    controller: 'company_users',
    action: 'index',
    path: '/user/company_users',
    verb: 'get'
  },
  company_users_update: {
    controller: 'company_users',
    action: 'update',
    path: '/user/company_users/:id',
    verb: 'patch'
  },
  company_users_destroy: {
    controller: 'company_users',
    action: 'destroy',
    path: '/user/company_users/:id',
    verb: 'delete'
  },
  invitations_index: {
    controller: 'invitations',
    action: 'index',
    path: '/user/invitations',
    verb: 'get'
  },
  invitations_create: {
    controller: 'invitations',
    action: 'create',
    path: '/user/invitations',
    verb: 'post'
  },
  invitations_destroy: {
    controller: 'invitations',
    action: 'destroy',
    path: '/user/invitations/:id',
    verb: 'delete'
  },
  invitations_resend: {
    controller: 'invitations',
    action: 'resend',
    path: '/user/invitations/:id/resend',
    verb: 'put'
  },
  sites_index: {
    controller: 'sites',
    action: 'index',
    path: '/user/sites',
    verb: 'get'
  },
  sites_create: {
    controller: 'sites',
    action: 'create',
    path: '/user/sites',
    verb: 'post'
  },
  sites_show: {
    controller: 'sites',
    action: 'show',
    path: '/user/sites/:id',
    verb: 'get'
  },
  sites_update: {
    controller: 'sites',
    action: 'update',
    path: '/user/sites/:id',
    verb: 'patch'
  },
  sites_destroy: {
    controller: 'sites',
    action: 'destroy',
    path: '/user/sites/:id',
    verb: 'delete'
  },
  devices_index: {
    controller: 'devices',
    action: 'index',
    path: '/user/devices',
    verb: 'get'
  },
  gateways_update: {
    controller: 'gateways',
    action: 'update',
    path: '/user/gateways/:id',
    verb: 'patch'
  },
  plcs_refresh_interfaces: {
    controller: 'plcs',
    action: 'refresh_interfaces',
    path: '/user/plcs/:id/refresh_interfaces',
    verb: 'post'
  },
  plcs_show: {
    controller: 'plcs',
    action: 'show',
    path: '/user/plcs/:id',
    verb: 'get'
  },
  plcs_update: {
    controller: 'plcs',
    action: 'update',
    path: '/user/plcs/:id',
    verb: 'patch'
  },
  modbus_devices_refresh_values: {
    controller: 'modbus_devices',
    action: 'refresh_values',
    path: '/user/modbus_devices/:id/refresh_values',
    verb: 'post'
  },
  modbus_devices_create: {
    controller: 'modbus_devices',
    action: 'create',
    path: '/user/modbus_devices',
    verb: 'post'
  },
  modbus_devices_show: {
    controller: 'modbus_devices',
    action: 'show',
    path: '/user/modbus_devices/:id',
    verb: 'get'
  },
  modbus_devices_update: {
    controller: 'modbus_devices',
    action: 'update',
    path: '/user/modbus_devices/:id',
    verb: 'patch'
  },
  modbus_devices_destroy: {
    controller: 'modbus_devices',
    action: 'destroy',
    path: '/user/modbus_devices/:id',
    verb: 'delete'
  },
  measurement_points_bulk_write: {
    controller: 'measurement_points',
    action: 'bulk_write',
    path: '/user/measurement_points/bulk_write',
    verb: 'post'
  },
  measurement_points_write: {
    controller: 'measurement_points',
    action: 'write',
    path: '/user/measurement_points/:id/write',
    verb: 'post'
  },
  measurement_points_operation_mode_config: {
    controller: 'measurement_points',
    action: 'operation_mode_config',
    path: '/user/measurement_points/:id/operation_mode_config',
    verb: 'get'
  },
  measurement_points_update: {
    controller: 'measurement_points',
    action: 'update',
    path: '/user/measurement_points/:id',
    verb: 'patch'
  },
  alerts_index: {
    controller: 'alerts',
    action: 'index',
    path: '/user/alerts',
    verb: 'get'
  },
  alerts_show: {
    controller: 'alerts',
    action: 'show',
    path: '/user/alerts/:id',
    verb: 'get'
  },
  alert_rules_index: {
    controller: 'alert_rules',
    action: 'index',
    path: '/user/alert_rules',
    verb: 'get'
  },
  alert_rules_create: {
    controller: 'alert_rules',
    action: 'create',
    path: '/user/alert_rules',
    verb: 'post'
  },
  alert_rules_new: {
    controller: 'alert_rules',
    action: 'new',
    path: '/user/alert_rules/new',
    verb: 'get'
  },
  alert_rules_edit: {
    controller: 'alert_rules',
    action: 'edit',
    path: '/user/alert_rules/:id/edit',
    verb: 'get'
  },
  alert_rules_update: {
    controller: 'alert_rules',
    action: 'update',
    path: '/user/alert_rules/:id',
    verb: 'patch'
  },
  alert_rules_destroy: {
    controller: 'alert_rules',
    action: 'destroy',
    path: '/user/alert_rules/:id',
    verb: 'delete'
  },
  alert_subscriptions_index: {
    controller: 'alert_subscriptions',
    action: 'index',
    path: '/user/notification_settings',
    verb: 'get'
  },
  alert_subscriptions_create: {
    controller: 'alert_subscriptions',
    action: 'create',
    path: '/user/notification_settings',
    verb: 'post'
  },
  alert_subscriptions_update: {
    controller: 'alert_subscriptions',
    action: 'update',
    path: '/user/notification_settings/:id',
    verb: 'patch'
  },
  alert_subscriptions_destroy: {
    controller: 'alert_subscriptions',
    action: 'destroy',
    path: '/user/notification_settings/:id',
    verb: 'delete'
  },
  live_poll: {
    controller: 'live',
    action: 'poll',
    path: '/user/live/poll',
    verb: 'get'
  },
  live_poll_weather: {
    controller: 'live',
    action: 'poll_weather',
    path: '/user/live/poll_weather',
    verb: 'get'
  },
  analytics_show: {
    controller: 'analytics',
    action: 'show',
    path: '/user/analytics',
    verb: 'get'
  },
  analytics_hourly: {
    controller: 'analytics',
    action: 'hourly',
    path: '/user/analytics/hourly',
    verb: 'get'
  },
  analytics_raw: {
    controller: 'analytics',
    action: 'raw',
    path: '/user/analytics/raw',
    verb: 'get'
  },
  analytics_weather_hourly: {
    controller: 'analytics',
    action: 'weather_hourly',
    path: '/user/analytics/weather_hourly',
    verb: 'get'
  },
  analytics_weather_raw: {
    controller: 'analytics',
    action: 'weather_raw',
    path: '/user/analytics/weather_raw',
    verb: 'get'
  },
  programs_index: {
    controller: 'programs',
    action: 'index',
    path: '/user/programs',
    verb: 'get'
  },
  programs_show_plc: {
    controller: 'programs',
    action: 'show_plc',
    path: '/user/programs/plc/:id',
    verb: 'get'
  },
  programs_show_modbus_device: {
    controller: 'programs',
    action: 'show_modbus_device',
    path: '/user/programs/modbus_device/:id',
    verb: 'get'
  },
  dashboard_show: {
    controller: 'dashboard',
    action: 'show',
    path: '/user/dashboard',
    verb: 'get'
  }
};
