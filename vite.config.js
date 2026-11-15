import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
//import vueDevTools from 'vite-plugin-vue-devtools'

// CSP només per al build de producció. Si s'apliqués al servidor de
// desenvolupament, trencaria el HMR de Vite (ws://localhost).
function cspPlugin() {
  const contentSecurityPolicy = [
    "default-src 'self'",
    "script-src 'self'",
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: https:",
    "media-src 'self' https:",
    "font-src 'self' data:",
    "connect-src 'self' https://*.supabase.co wss://*.supabase.co",
    "frame-src https://www.youtube.com https://www.youtube-nocookie.com",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'"
  ].join('; ')

  return {
    name: 'inject-csp',
    apply: 'build',
    transformIndexHtml() {
      return [
        {
          tag: 'meta',
          attrs: {
            'http-equiv': 'Content-Security-Policy',
            content: contentSecurityPolicy
          },
          injectTo: 'head-prepend'
        }
      ]
    }
  }
}

// https://vite.dev/config/
export default defineConfig({
  base: '/Pokegrammys2026/',
  plugins: [
    vue(),
    cspPlugin(),
    //vueDevTools(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    },
  },
})
