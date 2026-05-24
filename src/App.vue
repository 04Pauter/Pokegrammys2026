<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import Menubar from 'primevue/menubar'

const router = useRouter()
const items = ref([
  { label: 'Login', icon: 'pi pi-unlock', command: () => router.push('/') },
  { label: 'Home', icon: 'pi pi-user', command: () => router.push('/Home') },
  { label: 'Registro', icon: 'pi pi-user', command: () => router.push('/Register') },
  { label: 'Pokecuento', icon: 'pi pi-youtube', command: () => router.push('/Pokecuento') }
])
</script>

<template>
  <Menubar :model="items" breakpoint="0" />
  <router-view />
</template>

<style scoped></style>
