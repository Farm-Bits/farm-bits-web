// Vue
import { createApp, h } from 'vue';
import { createInertiaApp, Head, Link } from '@inertiajs/vue3';
import { createPinia } from 'pinia';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';

// Components
import {
  CAvatar,
  CBadge,
  CButton,
  CCard,
  CCardBody,
  CCardGroup,
  CCardHeader,
  CCardImage,
  CCardText,
  CCardTitle,
  CCol,
  CCollapse,
  CContainer,
  CDropdown,
  CDropdownDivider,
  CDropdownHeader,
  CDropdownItem,
  CDropdownMenu,
  CDropdownToggle,
  CFooter,
  CForm,
  CFormCheck,
  CFormInput,
  CFormSelect,
  CHeader,
  CHeaderBrand,
  CHeaderDivider,
  CHeaderNav,
  CHeaderToggler,
  CInputGroup,
  CInputGroupText,
  CLoadingButton,
  CMultiSelect,
  CNavbar,
  CNavbarBrand,
  CNavbarNav,
  CNavbarToggler,
  CNavGroup,
  CNavItem,
  CNavLink,
  CNavTitle,
  CProgress,
  CRow,
  CSidebar,
  CSidebarBrand,
  CSidebarFooter,
  CSidebarHeader,
  CSidebarNav,
  CSidebarToggler,
  CToast,
  CToastBody,
  CToastClose,
  CToaster,
  CToastHeader
} from '@coreui/vue-pro';
import { CIcon } from '@coreui/icons-vue';
import {
  cilAccountLogout,
  cilArrowRight,
  cilArrowLeft,
  cilBarChart,
  cilBellExclamation,
  cilCheckAlt,
  cilDescription,
  cilGem,
  cilLockLocked,
  cilMenu,
  cilPeople,
  cilPlus,
  cilPuzzle,
  cilSettings,
  cilSpeedometer,
  cilUser
} from '@coreui/icons';
import '@coreui/coreui-pro/dist/css/coreui.min.css';
import FlashMessages from './components/FlashMessages.vue';

// Configuration
import { resolvePage } from './pages';
import './styles/application.css';

export default function () {
  createInertiaApp({
    resolve: resolvePage,
    progress: {
      delay: 50,
      includeCSS: true,
      showSpinner: false
    },
    setup({ el, App, props, plugin }) {
      const app = createApp({ render: () => h(App, props) });
      const pinia = createPinia();
      pinia.use(piniaPluginPersistedstate);

      app.use(plugin);
      app.use(pinia);

      // Inertia
      app.component('Head', Head);
      app.component('Link', Link);

      // Core UI
      app.provide('icons', {
        cilAccountLogout,
        cilArrowRight,
        cilArrowLeft,
        cilBarChart,
        cilBellExclamation,
        cilCheckAlt,
        cilDescription,
        cilGem,
        cilLockLocked,
        cilMenu,
        cilPeople,
        cilPlus,
        cilPuzzle,
        cilSettings,
        cilSpeedometer,
        cilUser
      });
      app.component('CAvatar', CAvatar);
      app.component('CBadge', CBadge);
      app.component('CButton', CButton);
      app.component('CCard', CCard);
      app.component('CCardBody', CCardBody);
      app.component('CCardGroup', CCardGroup);
      app.component('CCardHeader', CCardHeader);
      app.component('CCardImage', CCardImage);
      app.component('CCardText', CCardText);
      app.component('CCardTitle', CCardTitle);
      app.component('CCol', CCol);
      app.component('CCollapse', CCollapse);
      app.component('CContainer', CContainer);
      app.component('CDropdown', CDropdown);
      app.component('CDropdownDivider', CDropdownDivider);
      app.component('CDropdownHeader', CDropdownHeader);
      app.component('CDropdownItem', CDropdownItem);
      app.component('CDropdownMenu', CDropdownMenu);
      app.component('CDropdownToggle', CDropdownToggle);
      app.component('CFooter', CFooter);
      app.component('CForm', CForm);
      app.component('CFormCheck', CFormCheck);
      app.component('CFormInput', CFormInput);
      app.component('CFormSelect', CFormSelect);
      app.component('CHeader', CHeader);
      app.component('CHeaderBrand', CHeaderBrand);
      app.component('CHeaderDivider', CHeaderDivider);
      app.component('CHeaderNav', CHeaderNav);
      app.component('CHeaderToggler', CHeaderToggler);
      app.component('CInputGroup', CInputGroup);
      app.component('CInputGroupText', CInputGroupText);
      app.component('CIcon', CIcon);
      app.component('CLoadingButton', CLoadingButton);
      app.component('CMultiSelect', CMultiSelect);
      app.component('CNavbar', CNavbar);
      app.component('CNavbarBrand', CNavbarBrand);
      app.component('CNavbarNav', CNavbarNav);
      app.component('CNavbarToggler', CNavbarToggler);
      app.component('CNavGroup', CNavGroup);
      app.component('CNavItem', CNavItem);
      app.component('CNavLink', CNavLink);
      app.component('CNavTitle', CNavTitle);
      app.component('CProgress', CProgress);
      app.component('CRow', CRow);
      app.component('CSidebar', CSidebar);
      app.component('CSidebarBrand', CSidebarBrand);
      app.component('CSidebarFooter', CSidebarFooter);
      app.component('CSidebarHeader', CSidebarHeader);
      app.component('CSidebarNav', CSidebarNav);
      app.component('CSidebarToggler', CSidebarToggler);
      app.component('CToast', CToast);
      app.component('CToastBody', CToastBody);
      app.component('CToastClose', CToastClose);
      app.component('CToaster', CToaster);
      app.component('CToastHeader', CToastHeader);

      // Custom
      app.component('FlashMessages', FlashMessages);

      app.mount(el);
    }
  });
}
