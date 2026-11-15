import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase.js'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const profile = ref(null)
  const loading = ref(true)
  const profileLoading = ref(true)
  /* Sessió temporal creada per l'enllaç "Recupera la contrasenya".
     La fem servir per redirigir l'usuari a /Reset en lloc de Login. */
  const isRecovery = ref(false)

  const isAuthenticated = computed(() => !!user.value)
  const isAdmin = computed(() => profile.value?.role === 'admin')

  /* --- Resolució de la sessió ---------------------------------
     `ensureInit()` és idempotent: el router l'espera abans de
     decidir si una ruta requereix autenticació o rol d'admin.
     Abans el guard retornava `next()` mentre la sessió encara no
     s'havia resolt i, per tant, saltava la comprovació d'admin. */
  let initPromise = null
  let resolveReady
  const ready = new Promise(resolve => { resolveReady = resolve })
  let subscription = null

  async function fetchProfile(userId) {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle()
      if (error) {
        console.error('Error fetching profile:', error)
        profile.value = null
      } else {
        profile.value = data ?? null
      }
    } catch (err) {
      console.error('Error fetching profile:', err)
      profile.value = null
    } finally {
      profileLoading.value = false
    }
  }

  async function init() {
    try {
      const { data } = await supabase.auth.getSession()
      user.value = data.session?.user ?? null

      if (user.value) {
        await fetchProfile(user.value.id)
      } else {
        profileLoading.value = false
      }
    } catch (err) {
      console.error('Error initialising auth:', err)
      profileLoading.value = false
    } finally {
      loading.value = false
      resolveReady()
    }

    if (!subscription) {
      subscription = supabase.auth.onAuthStateChange((event, session) => {
        user.value = session?.user ?? null
        // L'enllaç de recuperació crea una sessió especial: el guard
        // la fa servir per portar l'usuari a /Reset en lloc de Login.
        if (event === 'PASSWORD_RECOVERY') isRecovery.value = true
        if (session?.user) {
          fetchProfile(session.user.id)
        } else {
          profile.value = null
          profileLoading.value = false
          // Sense sessió no pot haver-hi recuperació pendent
          // (p. ex. després del signOut de la vista /Reset).
          isRecovery.value = false
        }
      })
    }
  }

  function ensureInit() {
    if (!initPromise) initPromise = init()
    return ready
  }

  async function login(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
    // Sense això, `router.push('/Home')` corria abans que
    // `onAuthStateChange` actualitzés `user` i el guard rebotava
    // l'usuari a /Login.
    if (data?.user) {
      user.value = data.user
      await fetchProfile(data.user.id)
    }
    return data?.user ?? null
  }

  /* El registre amb la confirmació per correu desactivada retorna
     sessió directament. Adoptem l'usuari de manera síncrona perquè
     el guard del router no el reboti a /Login mentre l'esdeveniment
     onAuthStateChange encara no ha arribat. */
  async function adoptSession(sessionUser) {
    if (!sessionUser) return
    user.value = sessionUser
    await fetchProfile(sessionUser.id)
  }

  async function logout() {
    await supabase.auth.signOut()
    // Es neteja l'estat local immediatament: el guard no ha de
    // veure una sessió que ja no existeix.
    user.value = null
    profile.value = null
    profileLoading.value = false
    isRecovery.value = false
  }

  return {
    user, profile, loading, profileLoading, isAuthenticated, isAdmin, isRecovery,
    init, ensureInit, login, logout, adoptSession, fetchProfile
  }
})
