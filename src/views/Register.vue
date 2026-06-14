<template>
  <div class="register-view">
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
      <h1 class="auth-title">{{ $t('auth.titleRegister') }}</h1>
      <p class="auth-subtitle">{{ $t('auth.registerSubtitle') || 'Crea el teu compte' }}</p>

      <form @submit.prevent="handleRegister" class="register-form auth-form">
        <div class="input-group">
          <input v-model="email" :placeholder="$t('auth.email')" type="email" required />
          <span class="input-glow" />
        </div>
        <div class="input-group">
          <input v-model="password" :placeholder="$t('auth.password')" type="password" required minlength="6" />
          <span class="input-glow" />
        </div>
        <div class="input-group">
          <input v-model="confirmPassword" :placeholder="$t('auth.confirmPassword')" type="password" required minlength="6" />
          <span class="input-glow" />
        </div>
        <Transition name="state-fade">
          <p v-if="errorMsg" class="error-msg">{{ errorMsg }}</p>
        </Transition>
        <Transition name="state-fade">
          <p v-if="successMsg" class="success-msg">{{ successMsg }}</p>
        </Transition>
        <button type="submit" class="btn-auth" :disabled="loading">
          <span class="btn-auth-text">{{ loading ? $t('auth.creatingAccount') : $t('auth.createAccount') }}</span>
          <span class="btn-auth-shine" />
        </button>
      </form>

      <p class="auth-switch">
        {{ $t('auth.hasAccount') || 'Ja tens compte?' }}
        <router-link to="/">{{ $t('auth.login') }}</router-link>
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '../lib/supabase.js'

const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const loading = ref(false)
const errorMsg = ref('')
const successMsg = ref('')

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

const handleRegister = async () => {
  errorMsg.value = ''
  successMsg.value = ''

  const { t } = useI18n()

  if (password.value !== confirmPassword.value) {
    errorMsg.value = t('auth.passwordsDontMatch')
    return
  }

  loading.value = true

  const { error } = await supabase.auth.signUp({
    email: email.value,
    password: password.value,
  })

  if (error) {
    errorMsg.value = error.message
    loading.value = false
  } else {
    successMsg.value = t('auth.accountCreated')
    loading.value = false
  }
}
</script>
