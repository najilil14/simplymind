import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// In production the dbdiagram app is deployed alongside SimplyMind at
// simplymind.nzilo.com/dbdiagram/, so all asset URLs must be prefixed
// with /dbdiagram/. In dev (vite dev server) the app is served at the
// root, so base stays "/".
export default defineConfig(({ command }) => ({
  base: command === 'build' ? '/dbdiagram/' : '/',
  plugins: [react()],
  optimizeDeps: {
    include: ['@dbml/core', '@dbml/parse'],
  },
}));
