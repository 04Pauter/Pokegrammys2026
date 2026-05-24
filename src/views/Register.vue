<template>
  <div class="register-view">
    <h1>Registre</h1>
    <form @submit.prevent="handleRegister" class="register-form">
      <input v-model="email" placeholder="Email" type="email" required />
      <input v-model="password" placeholder="Contraseña" type="password" required minlength="6" />
      <input v-model="confirmPassword" placeholder="Repetir contraseña" type="password" required minlength="6" />
      <p v-if="errorMsg" class="error">{{ errorMsg }}</p>
      <p v-if="successMsg" class="success">{{ successMsg }}</p>
      <button type="submit" :disabled="loading">
        {{ loading ? 'Creant compte...' : 'Crear compte' }}
      </button>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue'
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

  if (password.value !== confirmPassword.value) {
    errorMsg.value = 'Les contrasenyes no coincideixen'
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
    successMsg.value = 'Compte creat! Revisa el teu email per confirmar-lo.'
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

.error {
  color: #e74c3c;
  font-size: 0.875rem;
  margin: 0;
}

.success {
  color: #2ecc71;
  font-size: 0.875rem;
  margin: 0;
}
</style>