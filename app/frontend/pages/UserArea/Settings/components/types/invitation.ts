import { type User } from '@/types/inertia';
import type { Role } from '@/types/permissions';

export type ClientUser = User & {
  role: Role;
  status: string;
};

type InvitationStatus = 'pending' | 'expired';

export type Invitation = {
  id: number;
  email: string;
  role: Role;
  status: InvitationStatus;
  expired: boolean;
};
