import type { Role } from './permissions';
import type { Segment, Site } from './location';

const USER_SCOPES = ['admin_users', 'users'] as const;
export type UserScope = typeof USER_SCOPES[number];

export type Company = {
  id: number;
  name: string;
  color: string;
  require_2fa: boolean;
};

export type User = {
  id: number;
  name: string;
  email: string;
  otp_enabled_at: string | null;
};

export type SiteWithSegments = Site & {
  segments: Segment[];
};

declare module '@inertiajs/core' {
  interface PageProps {
    userScope?: UserScope;
    currentController?: string;
    currentAction?: string;
    currentUser?: User;
    currentCompany?: Company;
    currentRole?: Role;
    accessibleCompanies?: Company[];
    currentSite?: SiteWithSegments;
    accessibleSites?: Site[];
    openAlertCount?: number;
  }
};
