<template>
  <div class="login-view">
    <h1>{{ $t('auth.titleLogin') }}</h1>
    <form @submit.prevent="handleLogin" class="login-form">
      <input v-model="email" :placeholder="$t('auth.email')" type="email" required />
      <input v-model="password" :placeholder="$t('auth.password')" type="password" required />
      <p v-if="errorMsg" class="error">{{ errorMsg }}</p>
      <button type="submit" :disabled="loading">
        {{ loading ? $t('auth.loggingIn') : $t('auth.loginButton') }}
      </button>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth.js'

const router = useRouter()

const email = ref('')
const password = ref('')
const loading = ref(false)
const errorMsg = ref('')

const auth = useAuthStore()

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

<style scoped>
.login-view {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  flex: 1;
  text-align: center;
  gap: 1rem;
  padding: 2rem;
}

.login-view h1 {
  font-size: 2.5rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: -0.02em;
}

.login-form {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  width: 100%;
}
</style>