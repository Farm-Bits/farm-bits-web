// const pages = import.meta.env.SSR
//   ? import.meta.globEagerDefault('./pages/**/*.vue', { eager: true })
//   : import.meta.glob('./pages/**/*.vue', { eager: true });

// export async function resolvePage(name: string) {
//   const page = pages[`./pages/${name}.vue`];

//   if (!page) {
//     throw new Error(
//       `Unknown page ${name}. Is it located under Pages with a .vue extension?`
//     );
//   }

//   page.default.layout = page.default.layout || Layout;
//   return import.meta.env.SSR ? page : (await page).default;
// }

import { type DefineComponent } from 'vue';
import Layout from './layouts/Default.vue';

type PageModule = {
  default: DefineComponent & {
    layout?: DefineComponent;
  };
};

type GlobEagerImports = Record<string, PageModule>;

const pages: GlobEagerImports = import.meta.glob('./pages/**/*.vue', { eager: true }) as GlobEagerImports;

export async function resolvePage(name: string) {
  const page = pages[`./pages/${name}.vue`];

  if (!page) {
    throw new Error(
      `Unknown page ${name}. Is it located under Pages with a .vue extension?`
    );
  }

  (page.default as any).layout = page.default.layout || Layout;
  return page.default;
}
