<template>
  <div class="login-view">
    <!-- Background orbs -->
    <div class="auth-orb auth-orb-1" />
    <div class="auth-orb auth-orb-2" />
    <div class="auth-orb auth-orb-3" />

    <!-- Particles -->
    <div class="auth-particles">
      <div v-for="p in 8" :key="p" class="auth-particle" :style="particleStyle(p)" />
    </div>

    <div class="auth-content">
      <div class="auth-icon">
        <span class="auth-icon-inner">✦</span>
      </div>

      <!-- MODO 1: demanar l'enllaç de recuperació -->
      <template v-if="mode === 'request'">
        <h1 class="auth-title">{{ $t('auth.resetTitle') }}</h1>
        <p class="auth-subtitle">{{ $t('auth.resetSubtitle') }}</p>

        <form @submit.prevent="sendResetLink" class="login-form auth-form">
          <div class="input-group">
            <input v-model="email" :placeholder="$t('auth.email')" type="email" required />
            <span class="input-glow" />
          </div>
          <Transition name="state-fade">
            <p v-if="errorMsg" class="error-msg">{{ errorMsg }}</p>
          </Transition>
          <Transition name="state-fade">
            <p v-if="successMsg" class="success-msg">{{ successMsg }}</p>
          </Transition>
          <button type="submit" class="btn-auth" :disabled="loading">
            <span class="btn-auth-text">{{ loading ? $t('auth.sendingResetLink') : $t('auth.sendResetLink') }}</span>
            <span class="btn-auth-shine" />
          </button>
        </form>

        <p class="auth-switch">
          <router-link to="/">{{ $t('auth.login') }}</router-link>
        </p>
      </template>

      <!-- MODE 2: establir la contrasenya nova (sessió de recuperació) -->
      <template v-else>
        <h1 class="auth-title">{{ $t('auth.newPasswordTitle') }}</h1>

        <form @submit.prevent="updatePassword" class="login-form auth-form">
          <div class="input-group">
            <input v-model="password" :placeholder="$t('auth.newPasswordTitle')" :type="showPassword ? 'text' : 'password'" required minlength="8" />
            <button type="button" class="password-toggle" @click="showPassword = !showPassword" :aria-label="showPassword ? $t('auth.hidePassword') : $t('auth.showPassword')">
              <svg v-if="showPassword" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
                <line x1="1" y1="1" x2="23" y2="23"/>
              </svg>
              <svg v-else width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                <circle cx="12" cy="12" r="3"/>
              </svg>
            </button>
            <span class="input-glow" />
          </div>
          <div class="input-group">
            <input v-model="confirmPassword" :placeholder="$t('auth.confirmPassword')" type="password" required minlength="8" />
            <span class="input-glow" />
          </div>
          <Transition name="state-fade">
            <p v-if="errorMsg" class="error-msg">{{ errorMsg }}</p>
          </Transition>
          <Transition name="state-fade">
            <p v-if="successMsg" class="success-msg">{{ successMsg }}</p>
          </Transition>
          <button type="submit" class="btn-auth" :disabled="loading">
            <span class="btn-auth-text">{{ loading ? $t('auth.sendingResetLink') : $t('auth.updatePassword') }}</span>
            <span class="btn-auth-shine" />
          </button>
        </form>

        <p class="auth-switch">
          <router-link to="/Home">{{ $t('nav.home') }}</router-link>
        </p>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '../lib/supabase.js'

const { t } = useI18n()

const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const showPassword = ref(false)
const loading = ref(false)
const errorMsg = ref('')
const successMsg = ref('')

/* Els enllaços de recuperació apunten a la base de l'app (GH Pages no
   serveix res en rutes profundes, hi donaria 404). supabase-js detecta
   el hash #access_token=... de l'URL automàticament i crea la sessió
   temporal; el router redirigeix llavors a / amb isRecovery actiu. */
const mode = ref('request')
let subscription = null

function particleStyle(i) {
  const x = 10 + (i * 12) % 80
  const y = 5 + ((i * 17) % 70)
  const size = 2 + (i % 3) * 1.5
  return {
    left: x + '%',
    top: y + '%',
    width: size + 'px',
    height: size + 'px',
    animationDuration: 10 + i * 3 + 's',
    animationDelay: i * 1.2 + 's'
  }
}

onMounted(async () => {
  const { data } = await supabase.auth.getSession()
  if (data.session) {
    // Sessió activa (recuperació o usuari ja identificat): canviar contrasenya.
    mode.value = 'update'
  } else {
    // L'intercanvi del hash pot arribar mig instant després del getSession.
    subscription = supabase.auth.onAuthStateChange((event, session) => {
      if (session) {
        mode.value = 'update'
        if (event === 'PASSWORD_RECOVERY') {
          // Neteja el hash del navegador per no deixar tokens a l'historial.
          history.replaceState(null, '', `${window.location.pathname}${window.location.search}`)
        }
      }
    })
  }
})

onUnmounted(() => {
  if (subscription) subscription?.unsubscribe()
})

async function sendResetLink() {
  loading.value = true
  errorMsg.value = ''
  successMsg.value = ''

  try {
    const { error } = await supabase.auth.resetPasswordForEmail(email.value, {
      // Ruta-base de l'app: a GH Pages les rutes profundes donen 404.
      // Sessió temporal detectada a la base → el router duu a /Reset.
      redirectTo: `${window.location.origin}${import.meta.env.BASE_URL}`,
    })

    if (error) {
      console.error('Error sending reset email:', error)
      errorMsg.value = t('auth.resetError')
    } else {
      // Missatge neutre: no podem revelar si el correu té compte.
      successMsg.value = t('auth.resetLinkSent')
    }
  } catch (err) {
    console.error('Error sending reset email:', err)
    errorMsg.value = t('auth.resetError')
  } finally {
    loading.value = false
  }
}

async function updatePassword() {
  errorMsg.value = ''
  successMsg.value = ''

  if (password.value !== confirmPassword.value) {
    errorMsg.value = t('auth.passwordsDontMatch')
    return
  }

  loading.value = true

  try {
    const { data, error } = await supabase.auth.updateUser({
      password: password.value,
    })

    if (error) {
      console.error('Error updating password:', error)
      errorMsg.value = t('auth.passwordChangeError')
    } else if (data?.user) {
      successMsg.value = t('auth.passwordChanged')
      // La sessió temporal de recuperació ja no serveix per res:
      // Fem signOut per tornar al flux normal.
      await supabase.auth.signOut({ scope: 'local' })
      password.value = ''
      confirmPassword.value = ''
    }
  } catch (err) {
    console.error('Error updating password:', err)
    errorMsg.value = t('auth.passwordChangeError')
  } finally {
    loading.value = false
  }
}
</script>
