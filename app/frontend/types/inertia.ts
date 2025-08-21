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

declare module '@inertiajs/core' {
  interface PageProps {
    userScope?: UserScope;
    user?: User;
    client?: Client;
    clients?: Client[];
    sites?: Array<{ id: number; name: string }>;
  }
};
