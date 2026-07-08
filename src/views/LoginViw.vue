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
      <h1 class="auth-title">{{ $t('auth.titleLogin') }}</h1>
      <p class="auth-subtitle">{{ $t('auth.loginSubtitle') || 'Accedeix al teu compte' }}</p>

      <form @submit.prevent="handleLogin" class="login-form auth-form">
        <div class="input-group">
          <input v-model="email" :placeholder="$t('auth.email')" type="email" required />
          <span class="input-glow" />
        </div>
        <div class="input-group">
          <input v-model="password" :placeholder="$t('auth.password')" :type="showPassword ? 'text' : 'password'" required />
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
        <Transition name="state-fade">
          <p v-if="errorMsg" class="error-msg">{{ errorMsg }}</p>
        </Transition>
        <button type="submit" class="btn-auth" :disabled="loading">
          <span class="btn-auth-text">{{ loading ? $t('auth.loggingIn') : $t('auth.loginButton') }}</span>
          <span class="btn-auth-shine" />
        </button>
      </form>

      <p class="auth-switch">
        {{ $t('auth.noAccount') || 'No tens compte?' }}
        <router-link to="/Register">{{ $t('auth.register') }}</router-link>
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth.js'

const router = useRouter()

const email = ref('')
const password = ref('')
const showPassword = ref(false)
const loading = ref(false)
const errorMsg = ref('')

const auth = useAuthStore()

function particleStyle(i) {
  const x = 10 + (i * 12) % 80
  const y = 5 + ((i * 17) % 70)
  const size = 2 + (i % 3) * 1.5
  const dur = 10 + i * 3
  const delay = i * 1.2
  return {
    left: x + '%',
    top: y + '%',
    width: size + 'px',
    height: size + 'px',
    animationDuration: dur + 's',
    animationDelay: delay + 's'
  }
}

const handleLogin = async () => {
  loading.value = true
  errorMsg.value = ''

  try {
    await auth.login(email.value, password.value)
    router.push('/Home')
  } catch (error) {
    errorMsg.value = error.message
  } finally {
    loading.value = false
  }
}
</script>
