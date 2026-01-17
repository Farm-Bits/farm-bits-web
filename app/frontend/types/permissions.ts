// Auto-generated file - Do not edit manually
// Generated at: 2026-01-17 17:26:24 UTC

import type { Method } from '@inertiajs/core';

// Available roles from Roleable
export type Role = 'admin' | 'site_admin' | 'manager' | 'viewer';

export const ROLES = {
  admin: {
    name: 'Admin',
    description: 'Full access to all sites, management of company settings'
  },
  site_admin: {
    name: 'Site Admin',
    description: 'Full access on assigned sites'
  },
  manager: {
    name: 'Manager',
    description: 'Control on assigned sites'
  },
  viewer: {
    name: 'Viewer',
    description: 'Assigned sites, read-only'
  }
} as const;

// Valid controller keys
export type ControllerKey = 'dashboard' | 'my_account' | 'client_setup' | 'client_users' | 'invitations' | 'segments' | 'sites' | 'terminals' | 'plcs' | 'measurement_points';

// Route permissions mapping
export type RoutePermissions = {
  dashboard: {
    show: boolean;
  };
  my_account: {
    show: boolean;
    update: boolean;
    destroy: boolean;
  };
  client_setup: {
    new: boolean;
    edit: boolean;
    create: boolean;
    update: boolean;
    destroy: boolean;
  };
  client_users: {
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
  segments: {
    index: boolean;
    create: boolean;
    update: boolean;
    destroy: boolean;
  };
  sites: {
    index: boolean;
    create: boolean;
    show: boolean;
    update: boolean;
    destroy: boolean;
  };
  terminals: {
    index: boolean;
    update: boolean;
    destroy: boolean;
  };
  plcs: {
    show: boolean;
    update: boolean;
  };
  measurement_points: {
    write: boolean;
    update: boolean;
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
  dashboard_show: {
    controller: 'dashboard',
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
  client_setup_new: {
    controller: 'client_setup',
    action: 'new',
    path: '/user/client_setup/new',
    verb: 'get'
  },
  client_setup_edit: {
    controller: 'client_setup',
    action: 'edit',
    path: '/user/client_setup/edit',
    verb: 'get'
  },
  client_setup_create: {
    controller: 'client_setup',
    action: 'create',
    path: '/user/client_setup',
    verb: 'post'
  },
  client_setup_update: {
    controller: 'client_setup',
    action: 'update',
    path: '/user/client_setup',
    verb: 'put'
  },
  client_setup_destroy: {
    controller: 'client_setup',
    action: 'destroy',
    path: '/user/client_setup',
    verb: 'delete'
  },
  client_users_index: {
    controller: 'client_users',
    action: 'index',
    path: '/user/client_users',
    verb: 'get'
  },
  client_users_update: {
    controller: 'client_users',
    action: 'update',
    path: '/user/client_users/:id',
    verb: 'patch'
  },
  client_users_destroy: {
    controller: 'client_users',
    action: 'destroy',
    path: '/user/client_users/:id',
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
  segments_index: {
    controller: 'segments',
    action: 'index',
    path: '/user/segments',
    verb: 'get'
  },
  segments_create: {
    controller: 'segments',
    action: 'create',
    path: '/user/segments',
    verb: 'post'
  },
  segments_update: {
    controller: 'segments',
    action: 'update',
    path: '/user/segments/:id',
    verb: 'patch'
  },
  segments_destroy: {
    controller: 'segments',
    action: 'destroy',
    path: '/user/segments/:id',
    verb: 'delete'
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
  terminals_index: {
    controller: 'terminals',
    action: 'index',
    path: '/user/terminals',
    verb: 'get'
  },
  terminals_update: {
    controller: 'terminals',
    action: 'update',
    path: '/user/terminals/:id',
    verb: 'patch'
  },
  terminals_destroy: {
    controller: 'terminals',
    action: 'destroy',
    path: '/user/terminals/:id',
    verb: 'delete'
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
  measurement_points_update: {
    controller: 'measurement_points',
    action: 'update',
    path: '/user/measurement_points/:id',
    verb: 'patch'
  }
};
