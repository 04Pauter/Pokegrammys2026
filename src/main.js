import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { useAuthStore } from '@/stores/auth.js'

import PrimeVue from 'primevue/config'
import Menubar from 'primevue/menubar'

import './assets/global.css'
import 'primeicons/primeicons.css'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(PrimeVue)
app.component('Menubar', Menubar)

const auth = useAuthStore()
auth.init()

app.mount('#app')
