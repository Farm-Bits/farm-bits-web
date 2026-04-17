// Auto-generated file - Do not edit manually
// Generated at: 2026-04-15 18:42:16 UTC

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
export type ControllerKey = 'live' | 'my_account' | 'company_setup' | 'company_users' | 'invitations' | 'sites' | 'gateways' | 'plcs' | 'measurement_points' | 'analytics' | 'dashboard';

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
  gateways: {
    index: boolean;
    update: boolean;
    destroy: boolean;
  };
  plcs: {
    refresh_interfaces: boolean;
    show: boolean;
    update: boolean;
  };
  measurement_points: {
    write: boolean;
    operation_mode_config: boolean;
    update: boolean;
  };
  analytics: {
    show: boolean;
    hourly: boolean;
    raw: boolean;
    weather_hourly: boolean;
    weather_raw: boolean;
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
  gateways_index: {
    controller: 'gateways',
    action: 'index',
    path: '/user/gateways',
    verb: 'get'
  },
  gateways_update: {
    controller: 'gateways',
    action: 'update',
    path: '/user/gateways/:id',
    verb: 'patch'
  },
  gateways_destroy: {
    controller: 'gateways',
    action: 'destroy',
    path: '/user/gateways/:id',
    verb: 'delete'
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
  dashboard_show: {
    controller: 'dashboard',
    action: 'show',
    path: '/user/dashboard',
    verb: 'get'
  }
};
