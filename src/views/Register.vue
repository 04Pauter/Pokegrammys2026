<template>
  <div class="register-view">
    <h1>{{ $t('auth.titleRegister') }}</h1>
    <form @submit.prevent="handleRegister" class="register-form">
      <input v-model="email" :placeholder="$t('auth.email')" type="email" required />
      <input v-model="password" :placeholder="$t('auth.password')" type="password" required minlength="6" />
      <input v-model="confirmPassword" :placeholder="$t('auth.confirmPassword')" type="password" required minlength="6" />
      <p v-if="errorMsg" class="error">{{ errorMsg }}</p>
      <p v-if="successMsg" class="success">{{ successMsg }}</p>
      <button type="submit" :disabled="loading">
        {{ loading ? $t('auth.creatingAccount') : $t('auth.createAccount') }}
      </button>
    </form>
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

<style scoped>
.register-view {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  flex: 1;
  text-align: center;
  gap: 1rem;
  padding: 2rem;
}

.register-view h1 {
  font-size: 2.5rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: -0.02em;
}

.register-form {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  width: 100%;
}
</style>