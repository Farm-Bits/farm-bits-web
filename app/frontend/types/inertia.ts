export type UserScope = 'admin_users' | 'users';

export interface Client {
  id: number;
  name: string;
  color: string;
};

export interface User {
  id: number;
  name: string;
  email: string;
};

declare module '@inertiajs/core' {
  interface PageProps {
    userScope?: UserScope;
    user?: User;
    client?: Client;
    clients?: Client[];
    sites?: Array<{ id: number; name: string }>;
  }
};
