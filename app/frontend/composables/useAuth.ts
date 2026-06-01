import { computed } from 'vue';
import { usePage } from '@inertiajs/vue3'
import { type PageProps } from '@inertiajs/core';
import { ROUTES } from '@/types/permissions';
import type { Company } from '@/types/inertia';
import type { Site } from '@/types/location';

export default function useAuth<T extends PageProps>() {
  const page = usePage<T>();

  const pageProps = computed(() => page.props);
  const userScope = computed(() => page.props.userScope || 'users');
  const currentController = computed(() => page.props.currentController);
  const currentAction = computed(() => page.props.currentAction);
  const isSignedIn = computed(() => !!page.props.currentUser);
  const currentUser = computed(() => page.props.currentUser);
  const currentRole = computed(() => page.props.currentRole);
  const currentCompany = computed(() => page.props.currentCompany);
  const accessibleCompanies = computed(() => page.props.accessibleCompanies || []);
  const currentSite = computed(() => page.props.currentSite);
  const accessibleSites = computed(() => page.props.accessibleSites);
  const openAlertCount = computed(() => page.props.openAlertCount ?? 0);

  const isAdminUser = computed(() => {
    return isSignedIn.value && userScope.value === 'admin_users';
  });

  const rootObjectName = computed(() => {
    switch (userScope.value) {
      case 'users':
        return 'user';
      case 'admin_users':
        return 'admin_user';
      default:
        return 'user';
    }
  });

  function fillPath(template: string, params: Record<string, string | number | undefined>): string {
    return template.replace(/:([a-z_]+)/g, (_match, name: string) => {
      const value = params[name];
      if (value === undefined || value === null)
        throw new Error(`Missing route param ":${name}" for path "${template}"`);
      return String(value);
    });
  }

  // Builds a path from the ROUTES map, auto-injecting the current site / company.
  // Pass overrides (e.g. { id: plc.id } or a different site_id) as the 2nd arg.
  function routePath(key: keyof typeof ROUTES, params: Record<string, string | number> = {}): string {
    const route = ROUTES[key];
    return fillPath(route.path, {
      site_id: currentSite.value?.id,
      company_id: currentCompany.value?.id,
      ...params
    });
  }

  // Where to go when the user picks a different site: stay on the same page if it's
  // a site-scoped list/landing page, otherwise fall back to that site's Live page.
  function siteSwitchPath(siteId: Site['id']): string {
    const key = currentController.value && currentAction.value
      ? `${currentController.value}_${currentAction.value}` as keyof typeof ROUTES
      : undefined;
    const route = key ? ROUTES[key] : undefined;

    if (route && route.path.includes(':site_id') && !route.path.includes(':id'))
      return fillPath(route.path, { site_id: siteId, company_id: currentCompany.value?.id });

    return fillPath(ROUTES.live_show.path, { site_id: siteId });
  }

  const paths = computed(() => ({
    pages: {
      signIn: `/${userScope.value}/sign_in`,
      signUp: `/${userScope.value}/sign_up`,
      forgotPassword: `/${userScope.value}/password/new`,
      confirmation: `/${userScope.value}/confirmation/new`,
      unlock: `/${userScope.value}/unlock/new`,
      newCompany: `/${rootObjectName.value}/company_setup/new`,
      editCompany: currentCompany.value
        ? `/${rootObjectName.value}/companies/${currentCompany.value.id}/company_setup/edit`
        : '',
      companyEntry: (companyId: Company['id']) => `/?company_id=${companyId}`,
      myAccount: `/${rootObjectName.value}/my_account`,
      sessions: `/${rootObjectName.value}/sessions`
    },
    actions: {
      signIn: `/${userScope.value}/sign_in`,
      signUp: `/${userScope.value}`,
      signOut: `/${userScope.value}/sign_out`,
      resetPassword: `/${userScope.value}/password`,
      confirmation: `/${userScope.value}/confirmation`,
      unlock: `/${userScope.value}/unlock`,
      companySetup: `/${rootObjectName.value}/company_setup`,
      deleteSession: (sessionId: number) => `/${rootObjectName.value}/sessions/${sessionId}`,
      deleteAllSessions: `/${rootObjectName.value}/sessions/destroy_all`,
      twoFactor: `/${rootObjectName.value}/two_factors`,
      verifyOtp: `/${userScope.value}/otp/verify`,
      resendOtp: `/${userScope.value}/otp/resend`
    }
  }));

  const features = computed(() => ({
    canRegister: userScope.value === 'users',
    canConfirm: true,
    canUnlock: true,
    canRecover: true
  }));

  return {
    pageProps,
    userScope,
    isSignedIn,
    currentUser,
    currentCompany,
    currentRole,
    accessibleCompanies,
    openAlertCount,
    currentSite,
    accessibleSites,
    currentController,
    currentAction,
    isAdminUser,
    rootObjectName,
    routePath,
    siteSwitchPath,
    paths,
    features
  };
}
