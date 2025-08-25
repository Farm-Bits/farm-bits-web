// Vue
import { createApp, h } from 'vue';
import { createInertiaApp, Head, Link } from '@inertiajs/vue3';
import { createPinia } from 'pinia';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';

// Components
import {
  CAlert,
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
  CFormFeedback,
  CFormInput,
  CFormLabel,
  CFormSelect,
  CFormText,
  CHeader,
  CHeaderBrand,
  CHeaderDivider,
  CHeaderNav,
  CHeaderToggler,
  CInputGroup,
  CInputGroupText,
  CModal,
  CModalBody,
  CModalFooter,
  CModalHeader,
  CModalTitle,
  CNav,
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
  CSpinner,
  CTab,
  CTable,
  CTableBody,
  CTabContent,
  CTableDataCell,
  CTableHead,
  CTableHeaderCell,
  CTableRow,
  CTabList,
  CTabPanel,
  CTabs,
  CToast,
  CToastBody,
  CToastClose,
  CToaster,
  CToastHeader
} from '@coreui/vue';
import { CIcon } from '@coreui/icons-vue';
import {
  cilAccountLogout,
  cilArrowRight,
  cilArrowLeft,
  cilBarChart,
  cilBellExclamation,
  cilBuilding,
  cilCheck,
  cilCheckAlt,
  cilDescription,
  cilEnvelopeClosed,
  cilGem,
  cilLocationPin,
  cilLockLocked,
  cilMenu,
  cilOptions,
  cilPencil,
  cilPeople,
  cilPlus,
  cilPuzzle,
  cilSettings,
  cilSpeedometer,
  cilTrash,
  cilUser,
  cilUserPlus,
  cilUserX,
  cilWarning,
  cilX
} from '@coreui/icons';
import '@coreui/coreui/dist/css/coreui.min.css';
import ErrorMessages from './components/ErrorMessages.vue';
import VueSelect from 'vue3-select-component';

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
        cilBuilding,
        cilCheck,
        cilCheckAlt,
        cilDescription,
        cilEnvelopeClosed,
        cilGem,
        cilLocationPin,
        cilLockLocked,
        cilMenu,
        cilOptions,
        cilPencil,
        cilPeople,
        cilPlus,
        cilPuzzle,
        cilSettings,
        cilSpeedometer,
        cilTrash,
        cilUser,
        cilUserPlus,
        cilUserX,
        cilWarning,
        cilX
      });
      app.component('CAlert', CAlert);
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
      app.component('CFormFeedback', CFormFeedback);
      app.component('CFormInput', CFormInput);
      app.component('CFormLabel', CFormLabel);
      app.component('CFormSelect', CFormSelect);
      app.component('CFormText', CFormText);
      app.component('CHeader', CHeader);
      app.component('CHeaderBrand', CHeaderBrand);
      app.component('CHeaderDivider', CHeaderDivider);
      app.component('CHeaderNav', CHeaderNav);
      app.component('CHeaderToggler', CHeaderToggler);
      app.component('CInputGroup', CInputGroup);
      app.component('CInputGroupText', CInputGroupText);
      app.component('CIcon', CIcon);
      app.component('CModal', CModal);
      app.component('CModalBody', CModalBody);
      app.component('CModalFooter', CModalFooter);
      app.component('CModalHeader', CModalHeader);
      app.component('CModalTitle', CModalTitle);
      app.component('CNav', CNav);
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
      app.component('CSpinner', CSpinner);
      app.component('CTab', CTab);
      app.component('CTable', CTable);
      app.component('CTableBody', CTableBody);
      app.component('CTabContent', CTabContent);
      app.component('CTableDataCell', CTableDataCell);
      app.component('CTableHead', CTableHead);
      app.component('CTableHeaderCell', CTableHeaderCell);
      app.component('CTableRow', CTableRow);
      app.component('CTabList', CTabList);
      app.component('CTabPanel', CTabPanel);
      app.component('CTabs', CTabs);
      app.component('CToast', CToast);
      app.component('CToastBody', CToastBody);
      app.component('CToastClose', CToastClose);
      app.component('CToaster', CToaster);
      app.component('CToastHeader', CToastHeader);
      app.component('VueSelect', VueSelect);

      // Custom
      app.component('ErrorMessages', ErrorMessages);

      app.mount(el);
    }
  });
}
