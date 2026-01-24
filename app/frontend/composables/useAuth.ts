import { computed } from 'vue';
import { usePage } from '@inertiajs/vue3'
import { type PageProps } from '@inertiajs/core';

export default function useAuth<T extends PageProps>() {
  const page = usePage<T>();

  const pageProps = computed(() => page.props);
  const userScope = computed(() => page.props.userScope ? page.props.userScope : 'users');
  const isSignedIn = computed(() => !!page.props.currentUser);
  const currentUser = computed(() => page.props.currentUser);
  const currentRole = computed(() => page.props.currentRole);
  const currentCompany = computed(() => page.props.currentCompany);
  const accessibleCompanies = computed(() => page.props.accessibleCompanies || []);
  const currentSite = computed(() => page.props.currentSite);
  const accessibleSites = computed(() => page.props.accessibleSites);

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
        throw new Error(`Unknown user scope: ${userScope}`);
    }
  });

  const paths = computed(() => ({
    pages: {
      signIn: `/${userScope.value}/sign_in`,
      signUp: `/${userScope.value}/sign_up`,
      forgotPassword: `/${userScope.value}/password/new`,
      confirmation: `/${userScope.value}/confirmation/new`,
      unlock: `/${userScope.value}/unlock/new`,
      newCompany: `/${rootObjectName.value}/company_setup`,
      editCompany: `/${rootObjectName.value}/company_setup/edit`,
      myAccount: `/${rootObjectName.value}/my_account`
    },
    actions: {
      signIn: `/${userScope.value}/sign_in`,
      signUp: `/${userScope.value}`,
      signOut: `/${userScope.value}/sign_out`,
      resetPassword: `/${userScope.value}/password`,
      confirmation: `/${userScope.value}/confirmation`,
      unlock: `/${userScope.value}/unlock`,
      companySetup: `/${rootObjectName.value}/company_setup`
    },
    api: {
      users: `/${rootObjectName.value}/users`,
      invitations: `/${rootObjectName.value}/invitations`,
      roles: `/${rootObjectName.value}/roles`
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
    currentSite,
    accessibleSites,
    isAdminUser,
    rootObjectName,
    paths,
    features
  };
}
