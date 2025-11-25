import type { Role } from '../types/permissions';

export type UserScope = 'admin_users' | 'users';

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

export type Site = {
  id: number;
  name: string | null;
  country: string | null;
  city: string | null;
  latitude: string | number | null;
  longitude: string | number | null;
  altitude: string | number | null;
};

declare module '@inertiajs/core' {
  interface PageProps {
    userScope?: UserScope;
    user?: User;
    client?: Client;
    role?: Role;
    clients?: Client[];
    sites?: Site[];
  }
};
