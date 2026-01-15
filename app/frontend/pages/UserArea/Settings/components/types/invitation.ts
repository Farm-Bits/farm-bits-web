import { type User } from '@/types/inertia';
import type { Role } from '@/types/permissions';

export type ClientUser = {
  id: number;
  client_id: number;
  user_id: number;
  role: Role;
  user: User;
};

type InvitationStatus = 'pending' | 'expired';

export type Invitation = {
  id: number;
  email: string;
  role: Role;
  status: InvitationStatus;
  expired: boolean;
};
