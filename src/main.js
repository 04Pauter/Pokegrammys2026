import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { useAuthStore } from '@/stores/auth.js'

import PrimeVue from 'primevue/config'

import './assets/global.css'
import 'primeicons/primeicons.css'

import i18n from './i18n.js'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(PrimeVue)
app.use(i18n)

const auth = useAuthStore()
auth.init()

app.mount('#app')
