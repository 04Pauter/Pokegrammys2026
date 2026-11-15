import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { useAuthStore } from '@/stores/auth.js'

import PrimeVue from 'primevue/config'

import './assets/global.css'
import 'primeicons/primeicons.css'

import i18n from './i18n.js'

/* Anti-clickjacking: GitHub Pages no pot enviar l'header
   X-Frame-Options, i la directiva frame-ancestors no funciona dins
   <meta>. Si algú ens emmarca en un iframe, amaguem l'app i
   intentem escapar-ne. Sense això, un atacant podria fer clics
   invisibles sobre la pàgina (p. ex. votar en el nostre lloc). */
if (window.self !== window.top) {
  console.warn('Frame embedding no permès (anti-clickjacking)')
  document.documentElement.innerHTML = ''
  try {
    window.top.location = window.location
  } catch {
    /* top és cross-origin: no podem escapar-nos, però l'app
       ja està esborrada i no es mostra res. */
  }
}

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(PrimeVue)
app.use(i18n)

const auth = useAuthStore()
auth.ensureInit()

app.mount('#app')
