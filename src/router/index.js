import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth.js'

import HomeView from '../views/HomeView.vue'
import VotingView from '@/views/VotingView.vue'
import LoginViw from '@/views/LoginViw.vue'
import Register from '@/views/Register.vue'
import AdminView from '@/views/AdminView.vue'
import PokecuentoInfo from '@/views/PokecuentoInfo.vue'
import PokefilmInfo from '@/views/PokefilmInfo.vue'

const publicRoutes = ['Login', 'Registro']
const adminRoutes = ['AdminPanel']

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
      component: VotingView,
      props: { type: 'pokeserie' }
    },
    {
      path: '/Pokefilm',
      name: 'Pokefilm',
      component: VotingView,
      props: { type: 'pokefilm' }
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
    },
   {
      path: '/Admin',
      name: 'AdminPanel',
      component: AdminView
    },
    {
      path: '/Pokecuento/:id/info',
      name: 'PokecuentoInfo',
      component: PokecuentoInfo
    },
    {
      path: '/Pokefilm/:id/info',
      name: 'PokefilmInfo',
      component: PokefilmInfo
    }],
})

router.beforeEach((to, _from, next) => {
  const auth = useAuthStore()

  if (auth.loading || auth.profileLoading) return next()

  if (!auth.isAuthenticated && !publicRoutes.includes(to.name)) {
    return next({ name: 'Login' })
  }

  if (adminRoutes.includes(to.name) && !auth.isAdmin) {
    return next({ name: 'Home' })
  }

  next()
})

export default router
