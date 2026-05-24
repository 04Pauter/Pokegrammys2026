<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth.js'
import Menubar from 'primevue/menubar'

const router = useRouter()
const auth = useAuthStore()

const items = computed(() => {
  if (!auth.isAuthenticated) {
    return [
      { label: 'Login', icon: 'pi pi-unlock', command: () => router.push('/') },
      { label: 'Registro', icon: 'pi pi-user-plus', command: () => router.push('/Register') },
    ]
  }
  return [
    { label: 'Home', icon: 'pi pi-home', command: () => router.push('/Home') },
    { label: 'Pokecuento', icon: 'pi pi-youtube', command: () => router.push('/Pokecuento') },
    { label: 'Tancar sessió', icon: 'pi pi-sign-out', command: () => auth.logout().then(() => router.push('/')) },
  ]
})
</script>

<template>
  <Menubar :model="items" breakpoint="0" />
  <router-view />
</template>

<style scoped></style>
