import type { Role } from './permissions';
import type { Site } from './location';

const USER_SCOPES = ['admin_users', 'users'] as const;
export type UserScope = typeof USER_SCOPES[number];

export type Client = {
  id: number;
  name: string;
  color: string;
};

export type User = {
  id: number;
  name: string;
  email: string;
};

declare module '@inertiajs/core' {
  interface PageProps {
    userScope?: UserScope;
    user?: User;
    client?: Client;
    role?: Role;
    clients?: Client[];
    site?: Site;
    sites?: Site[];
  }
};
