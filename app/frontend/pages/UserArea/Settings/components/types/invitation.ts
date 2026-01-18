import { type User } from '@/types/inertia';
import type { Site } from '@/types/location';
import type { Role } from '@/types/permissions';

export type ClientUser = {
  id: number;
  client_id: number;
  user_id: number;
  role: Role;
  user: User;
  site_ids?: Site['id'][];
};

type InvitationStatus = 'pending' | 'expired';

export type Invitation = {
  id: number;
  email: string;
  role: Role;
  status: InvitationStatus;
  expired: boolean;
  site_ids?: Site['id'][];
};

export type ChangeRoleData = {
  role: Role;
  site_ids?: Site['id'][];
};

export type InvitationData = {
  email: string;
  role: Role;
  site_ids?: Site['id'][];
};
