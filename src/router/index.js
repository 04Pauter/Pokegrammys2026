import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth.js'

const publicRoutes = ['Login', 'Registro']
const adminRoutes = ['AdminPanel']

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [{
      path: '/',
      name: 'Login',
      component: () => import('@/views/LoginViw.vue')
    },
    {
      path: '/Pokecuento',
      name: 'Pokecuento',
      component: () => import('@/views/VotingView.vue'),
      props: { type: 'pokeserie' }
    },
    {
      path: '/Pokefilm',
      name: 'Pokefilm',
      component: () => import('@/views/VotingView.vue'),
      props: { type: 'pokefilm' }
    },
    {
      path: '/Home',
      name: 'Home',
      component: () => import('@/views/HomeView.vue')
    },
    {
      path: '/Register',
      name: 'Registro',
      component: () => import('@/views/RegisterView.vue')
    },
    {
      path: '/Admin',
      name: 'AdminPanel',
      component: () => import('@/views/AdminView.vue')
    },
    {
      path: '/Pokecuento/:id/info',
      name: 'PokecuentoInfo',
      component: () => import('@/views/PokecuentoInfo.vue')
    },
    {
      path: '/Pokefilm/:id/info',
      name: 'PokefilmInfo',
      component: () => import('@/views/PokefilmInfo.vue')
    },
    {
      path: '/Resultats',
      name: 'Resultats',
      component: () => import('@/views/ResultatsView.vue')
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
