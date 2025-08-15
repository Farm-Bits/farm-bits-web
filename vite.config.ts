import { defineConfig } from 'vite';
import VueDevTools from 'vite-plugin-vue-devtools';
import RubyPlugin from 'vite-plugin-ruby';
import vue from '@vitejs/plugin-vue';
import FullReload from 'vite-plugin-full-reload';
import path from 'path';
import themePlugin from './vite/plugins/themePlugin';

export default defineConfig({
  plugins: [
    VueDevTools(),
    RubyPlugin(),
    vue(),
    FullReload(['config/routes.rb', 'app/views/**/*'], { delay: 200 }),
    themePlugin()
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'app/frontend'),
    }
  }
});
