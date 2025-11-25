// Auto-generated file - Do not edit manually
// Generated at: 2025-11-25 18:34:46 UTC

import type { Method } from '@inertiajs/core';

// Available roles from Roleable
export type Role = 'admin' | 'manager' | 'viewer';

export const ROLES = {
  admin: {
    name: 'Admin',
    description: 'Full access to all sites, management of company settings'
  },
  manager: {
    name: 'Manager',
    description: 'Assigned sites with edit access'
  },
  viewer: {
    name: 'Viewer',
    description: 'Assigned sites, read-only'
  }
} as const;

// Valid controller keys
export type ControllerKey = 'dashboard' | 'my_account' | 'client_setup' | 'users' | 'invitations' | 'sites' | 'protocols';

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
  users: {
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
    update: boolean;
    destroy: boolean;
  };
  protocols: {
    index: boolean;
    create: boolean;
    new: boolean;
    edit: boolean;
    show: boolean;
    update: boolean;
    destroy: boolean;
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
  users_index: {
    controller: 'users',
    action: 'index',
    path: '/user/users',
    verb: 'get'
  },
  users_update: {
    controller: 'users',
    action: 'update',
    path: '/user/users',
    verb: 'put'
  },
  users_destroy: {
    controller: 'users',
    action: 'destroy',
    path: '/user/users',
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
  protocols_index: {
    controller: 'protocols',
    action: 'index',
    path: '/user/protocols',
    verb: 'get'
  },
  protocols_create: {
    controller: 'protocols',
    action: 'create',
    path: '/user/protocols',
    verb: 'post'
  },
  protocols_new: {
    controller: 'protocols',
    action: 'new',
    path: '/user/protocols/new',
    verb: 'get'
  },
  protocols_edit: {
    controller: 'protocols',
    action: 'edit',
    path: '/user/protocols/:id/edit',
    verb: 'get'
  },
  protocols_show: {
    controller: 'protocols',
    action: 'show',
    path: '/user/protocols/:id',
    verb: 'get'
  },
  protocols_update: {
    controller: 'protocols',
    action: 'update',
    path: '/user/protocols/:id',
    verb: 'patch'
  },
  protocols_destroy: {
    controller: 'protocols',
    action: 'destroy',
    path: '/user/protocols/:id',
    verb: 'delete'
  }
};
