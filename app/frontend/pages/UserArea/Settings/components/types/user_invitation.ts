import { type User } from '@/types/inertia';

type UserRole = 'admin' | 'manager' | 'viewer';

export type Role = {
  id: UserRole;
  name: string;
  description: string;
  level: number;
  permissions: {
    [key: string]: boolean;
  };
};

export type ClientUser = User & {
  role: UserRole;
  status: string;
};

type InvitationStatus = 'pending' | 'expired';

export type Invitation = {
  id: number;
  email: string;
  role: UserRole;
  status: InvitationStatus;
  expired: boolean;
};
