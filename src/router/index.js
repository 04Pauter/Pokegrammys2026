import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth.js'

const publicRoutes = ['Login', 'Registro', 'ResetPassword']
const adminRoutes = ['AdminPanel']

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  scrollBehavior(to, from, savedPosition) {
    // Sense això, la posició de scroll es heretava entre rutes i la
    // pàgina nova obria a mitjan camí (sovint en una zona buida).
    if (savedPosition) return savedPosition
    if (to.hash) return { el: to.hash, behavior: 'smooth' }
    return { top: 0 }
  },
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
      path: '/Reset',
      name: 'ResetPassword',
      component: () => import('@/views/ResetPasswordView.vue')
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
    },
    {
      path: '/:pathMatch(.*)*',
      redirect: '/Home'
    }],
})

router.beforeEach(async (to, _from, next) => {
  const auth = useAuthStore()

  // S'espera la resolució de la sessió abans de decidir. Abans es
  // retornava `next()` mentre `auth.loading` era cert i això saltava
  // tant la comprovació d'autenticació com la d'admin.
  await auth.ensureInit()

  if (!auth.isAuthenticated && !publicRoutes.includes(to.name)) {
    return next({ name: 'Login' })
  }

  /* Un enllaç de recuperació aterra a la base de l'app amb una sessió
     temporal (el hash el detecta supabase-js). Si encara estem a
     Login, portem l'usuari a la vista de contrasenya nova. */
  if (to.name === 'Login' && auth.isRecovery) {
    return next({ name: 'ResetPassword' })
  }

  if (adminRoutes.includes(to.name) && !auth.isAdmin) {
    return next({ name: 'Home' })
  }

  next()
})

export default router
