// Auto-generated file - Do not edit manually
// Generated at: 2025-11-21 10:58:05 UTC

// Available roles from Roleable
export type UserRole = 'admin' | 'manager' | 'viewer';

export const USER_ROLES = {
  ADMIN: 'admin' as const,
  MANAGER: 'manager' as const,
  VIEWER: 'viewer' as const
} as const;

// Valid controller keys
export type ControllerKey = 'dashboard' | 'my_account' | 'client_setup' | 'roles' | 'users' | 'invitations' | 'protocols';

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
  roles: {
    index: boolean;
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
  role: UserRole;
  routePermissions: RoutePermissions;
};

// Route information
export type RouteInfo = {
  controller: string;
  action: string;
  path: string;
  verb: string;
};

export const ROUTES: Record<string, RouteInfo> = {
  dashboard_show: {
    controller: 'dashboard',
    action: 'show',
    path: '/user',
    verb: 'GET'
  },
  my_account_show: {
    controller: 'my_account',
    action: 'show',
    path: '/user/my_account',
    verb: 'GET'
  },
  my_account_update: {
    controller: 'my_account',
    action: 'update',
    path: '/user/my_account',
    verb: 'PUT'
  },
  my_account_destroy: {
    controller: 'my_account',
    action: 'destroy',
    path: '/user/my_account',
    verb: 'DELETE'
  },
  client_setup_new: {
    controller: 'client_setup',
    action: 'new',
    path: '/user/client_setup/new',
    verb: 'GET'
  },
  client_setup_edit: {
    controller: 'client_setup',
    action: 'edit',
    path: '/user/client_setup/edit',
    verb: 'GET'
  },
  client_setup_create: {
    controller: 'client_setup',
    action: 'create',
    path: '/user/client_setup',
    verb: 'POST'
  },
  client_setup_update: {
    controller: 'client_setup',
    action: 'update',
    path: '/user/client_setup',
    verb: 'PUT'
  },
  client_setup_destroy: {
    controller: 'client_setup',
    action: 'destroy',
    path: '/user/client_setup',
    verb: 'DELETE'
  },
  roles_index: {
    controller: 'roles',
    action: 'index',
    path: '/user/roles',
    verb: 'GET'
  },
  users_index: {
    controller: 'users',
    action: 'index',
    path: '/user/users',
    verb: 'GET'
  },
  users_update: {
    controller: 'users',
    action: 'update',
    path: '/user/users',
    verb: 'PUT'
  },
  users_destroy: {
    controller: 'users',
    action: 'destroy',
    path: '/user/users',
    verb: 'DELETE'
  },
  invitations_index: {
    controller: 'invitations',
    action: 'index',
    path: '/user/invitations',
    verb: 'GET'
  },
  invitations_create: {
    controller: 'invitations',
    action: 'create',
    path: '/user/invitations',
    verb: 'POST'
  },
  invitations_destroy: {
    controller: 'invitations',
    action: 'destroy',
    path: '/user/invitations/:id',
    verb: 'DELETE'
  },
  invitations_resend: {
    controller: 'invitations',
    action: 'resend',
    path: '/user/invitations/:id/resend',
    verb: 'PUT'
  },
  protocols_index: {
    controller: 'protocols',
    action: 'index',
    path: '/user/protocols',
    verb: 'GET'
  },
  protocols_create: {
    controller: 'protocols',
    action: 'create',
    path: '/user/protocols',
    verb: 'POST'
  },
  protocols_new: {
    controller: 'protocols',
    action: 'new',
    path: '/user/protocols/new',
    verb: 'GET'
  },
  protocols_edit: {
    controller: 'protocols',
    action: 'edit',
    path: '/user/protocols/:id/edit',
    verb: 'GET'
  },
  protocols_show: {
    controller: 'protocols',
    action: 'show',
    path: '/user/protocols/:id',
    verb: 'GET'
  },
  protocols_update: {
    controller: 'protocols',
    action: 'update',
    path: '/user/protocols/:id',
    verb: 'PATCH'
  },
  protocols_destroy: {
    controller: 'protocols',
    action: 'destroy',
    path: '/user/protocols/:id',
    verb: 'DELETE'
  }
};
