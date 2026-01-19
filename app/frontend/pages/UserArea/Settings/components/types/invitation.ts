import { type User } from '@/types/inertia';
import type { Site } from '@/types/location';
import type { Role } from '@/types/permissions';

export type ClientUser = {
  id: number;
  client_id: number;
  user_id: number;
  role: Role;
  user: User;
  visible_site_ids: Site['id'][];
  total_sites_count: number;
  has_other_sites: boolean;
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
