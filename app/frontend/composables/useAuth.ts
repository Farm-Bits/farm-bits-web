import { computed } from 'vue';
import { usePage } from '@inertiajs/vue3'
import { type PageProps } from '@inertiajs/core';

export default function useAuth<T extends PageProps>() {
  const page = usePage<T>();

  const pageProps = computed(() => page.props);

  const userScope = computed(() => page.props.userScope ? page.props.userScope : 'users');

  const user = computed(() => page.props.user);

  const client = computed(() => page.props.client);

  const clients = computed(() => page.props.clients || []);

  const sites = computed(() => page.props.sites);

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
      newClient: `/${rootObjectName.value}/client_setup`,
      editClient: `/${rootObjectName.value}/client_setup/edit`
    },
    actions: {
      signIn: `/${userScope.value}/sign_in`,
      signUp: `/${userScope.value}`,
      signOut: `/${userScope.value}/sign_out`,
      resetPassword: `/${userScope.value}/password`,
      confirmation: `/${userScope.value}/confirmation`,
      unlock: `/${userScope.value}/unlock`,
      clientSetup: `/${rootObjectName.value}/client_setup`
    },
    api: {
      users: `/${rootObjectName.value}/users`
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
    user,
    client,
    clients,
    sites,
    rootObjectName,
    paths,
    features
  };
}
