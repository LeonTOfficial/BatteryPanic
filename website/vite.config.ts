import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import {defineConfig} from 'vite';

export default defineConfig(() => {
  return {
    base: '/BatteryPanic/',
    plugins: [react(), tailwindcss()],
    build: {
      outDir: path.resolve(__dirname, '../docs'),
      emptyOutDir: false,
      assetsDir: 'web-assets',
      rollupOptions: {
        input: {
          main: path.resolve(__dirname, 'index.html'),
          download: path.resolve(__dirname, 'download/index.html'),
          updates: path.resolve(__dirname, 'updates/index.html'),
          releaseNotes: path.resolve(__dirname, 'release-notes/0.5.13/index.html'),
        },
      },
    },
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '.'),
      },
    },
    server: {
      // HMR is disabled in AI Studio via DISABLE_HMR env var.
      // Do not modifyâfile watching is disabled to prevent flickering during agent edits.
      hmr: process.env.DISABLE_HMR !== 'true',
      // Disable file watching when DISABLE_HMR is true to save CPU during agent edits.
      watch: process.env.DISABLE_HMR === 'true' ? null : {},
    },
  };
});
