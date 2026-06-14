import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { useAuthStore } from '@/stores/auth.js'

import PrimeVue from 'primevue/config'
import Menubar from 'primevue/menubar'
import Button from 'primevue/button'
import Menu from 'primevue/menu'

import './assets/global.css'
import 'primeicons/primeicons.css'

import i18n from './i18n.js'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(PrimeVue)
app.use(i18n)
app.component('Menubar', Menubar)
app.component('Button', Button)
app.component('Menu', Menu)

const auth = useAuthStore()
auth.init()

app.mount('#app')
