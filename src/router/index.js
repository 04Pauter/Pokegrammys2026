import { createRouter, createWebHistory } from 'vue-router'

import HomeView from '../views/HomeView.vue'
import Pokecuento from '@/views/Pokecuento.vue'
import LoginViw from '@/views/LoginViw.vue'
import Register from '@/views/Register.vue'


const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [{
      path: '/',
      name: 'Login',
      component: LoginViw
    },
    {
      path: '/Pokecuento',
      name: 'Pokecuento',
      component: Pokecuento
    },
    {
      path: '/Home',
      name: 'Home',
      component: HomeView
    },
   {
      path: '/Register',
      name: 'Registro',
      component: Register
    }],
})

export default router
