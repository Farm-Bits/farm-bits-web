// Auto-generated file - Do not edit manually
// Generated at: 2025-11-21 10:58:14 UTC

import type { UserRole, RoutePermissions } from '../types/permissions';

// Permission matrix generated from actual policy testing
const PERMISSION_MATRIX: Record<UserRole, RoutePermissions> = {
  "admin": {
    "dashboard": {
      "show": true
    },
    "my_account": {
      "show": true,
      "update": true,
      "destroy": true
    },
    "client_setup": {
      "new": true,
      "edit": true,
      "create": true,
      "update": true,
      "destroy": true
    },
    "roles": {
      "index": false
    },
    "users": {
      "index": false,
      "update": false,
      "destroy": false
    },
    "invitations": {
      "index": false,
      "create": false,
      "destroy": false,
      "resend": false
    },
    "protocols": {
      "index": false,
      "create": false,
      "new": false,
      "edit": false,
      "show": false,
      "update": false,
      "destroy": false
    }
  },
  "manager": {
    "dashboard": {
      "show": true
    },
    "my_account": {
      "show": true,
      "update": true,
      "destroy": true
    },
    "client_setup": {
      "new": true,
      "edit": true,
      "create": true,
      "update": false,
      "destroy": false
    },
    "roles": {
      "index": false
    },
    "users": {
      "index": false,
      "update": false,
      "destroy": false
    },
    "invitations": {
      "index": false,
      "create": false,
      "destroy": false,
      "resend": false
    },
    "protocols": {
      "index": false,
      "create": false,
      "new": false,
      "edit": false,
      "show": false,
      "update": false,
      "destroy": false
    }
  },
  "viewer": {
    "dashboard": {
      "show": true
    },
    "my_account": {
      "show": true,
      "update": true,
      "destroy": true
    },
    "client_setup": {
      "new": true,
      "edit": true,
      "create": true,
      "update": false,
      "destroy": false
    },
    "roles": {
      "index": false
    },
    "users": {
      "index": false,
      "update": false,
      "destroy": false
    },
    "invitations": {
      "index": false,
      "create": false,
      "destroy": false,
      "resend": false
    },
    "protocols": {
      "index": false,
      "create": false,
      "new": false,
      "edit": false,
      "show": false,
      "update": false,
      "destroy": false
    }
  }
};

function isRoutePermissionKey(key: string): key is keyof RoutePermissions {
  for (const userRole in PERMISSION_MATRIX) {
    if (key in PERMISSION_MATRIX[userRole as UserRole]) {
      return true;
    }
  }
  return false;
}

function isActionKeyForController(
  controllerKey: keyof RoutePermissions,
  actionKey: string
): actionKey is keyof RoutePermissions[typeof controllerKey] {
  const sampleRole = Object.keys(PERMISSION_MATRIX)[0] as UserRole;
  const controllerPermissions = PERMISSION_MATRIX[sampleRole][controllerKey];
  return actionKey in controllerPermissions;
}

/**
 * Check if a user with a given role can access a specific controller/action
 * @param userRole - The role of the user
 * @param controller - The controller name (without 'user_area/' prefix)
 * @param action - The action name
 * @returns true if the user can access the action, false otherwise
 */
export function canAccess(
  userRole: UserRole,
  controller: string,
  action: string
): boolean {
  const rolePermissions = PERMISSION_MATRIX[userRole];
  if (!rolePermissions) {
    return false;
  }

  const controllerKey = controller.replace('/', '_');
  if (!isRoutePermissionKey(controllerKey) || !isActionKeyForController(controllerKey, action))
    return false;

  const controllerPermissions = rolePermissions[controllerKey];
  if (!controllerPermissions) {
    return false;
  }

  return controllerPermissions[action] === true;
}

/**
 * Get all permissions for a specific role
 * @param userRole - The role of the user
 * @returns The complete RoutePermissions object for the role
 */
export function getPermissionsForRole(userRole: UserRole): RoutePermissions {
  return PERMISSION_MATRIX[userRole] || {};
}

/**
 * Check if a user can perform any action in a controller
 * @param userRole - The role of the user
 * @param controller - The controller name
 * @returns true if the user can access any action in the controller
 */
export function canAccessController(
  userRole: UserRole,
  controller: string
): boolean {
  const rolePermissions = PERMISSION_MATRIX[userRole];
  if (!rolePermissions) {
    return false;
  }

  const controllerKey = controller.replace('/', '_');
  if (!isRoutePermissionKey(controllerKey))
    return false;

  const controllerPermissions = rolePermissions[controllerKey];
  if (!controllerPermissions) {
    return false;
  }

  return Object.values(controllerPermissions).some(permission => permission === true);
}

/**
 * Get accessible routes for a specific role
 * @param userRole - The role of the user
 * @returns Array of accessible routes with controller and action
 */
export function getAccessibleRoutes(userRole: UserRole): Array<{controller: string, action: string}> {
  const rolePermissions = PERMISSION_MATRIX[userRole];
  if (!rolePermissions) {
    return [];
  }

  const accessibleRoutes: Array<{controller: string, action: string}> = [];

  Object.entries(rolePermissions).forEach(([controllerKey, actions]) => {
    const controller = controllerKey.replace('_', '/');
    Object.entries(actions).forEach(([action, allowed]) => {
      if (allowed) {
        accessibleRoutes.push({ controller, action });
      }
    });
  });

  return accessibleRoutes;
}

/**
 * Check multiple permissions at once
 * @param userRole - The role of the user
 * @param permissions - Array of {controller, action} to check
 * @returns Object with each permission check result
 */
export function checkMultiplePermissions(
  userRole: UserRole,
  permissions: Array<{controller: string, action: string}>
): Record<string, boolean> {
  const results: Record<string, boolean> = {};

  permissions.forEach(({ controller, action }) => {
    const key = `${controller}:${action}`;
    results[key] = canAccess(userRole, controller, action);
  });

  return results;
}

// Export the permission matrix for debugging/inspection
export const permissionMatrix = PERMISSION_MATRIX;
