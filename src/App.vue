<script setup>
import { computed, ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth.js'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()
const { t, locale } = useI18n()

/* --- Theme --- */
const currentTheme = ref('dark')

function getSystemTheme() {
  return window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark'
}

function applyTheme(theme) {
  currentTheme.value = theme
  document.documentElement.setAttribute('data-theme', theme)
  localStorage.setItem('pokegrammys-theme', theme)
}

function toggleTheme() {
  applyTheme(currentTheme.value === 'dark' ? 'light' : 'dark')
}

onMounted(() => {
  const saved = localStorage.getItem('pokegrammys-theme')
  applyTheme(saved || getSystemTheme())

  window.matchMedia('(prefers-color-scheme: light)').addEventListener('change', (e) => {
    if (!localStorage.getItem('pokegrammys-theme')) {
      applyTheme(e.matches ? 'light' : 'dark')
    }
  })
})

/* --- Locale --- */
function setLocale(loc) {
  locale.value = loc
  localStorage.setItem('locale', loc)
}

const langMenu = ref()
const langItems = [
  { label: 'Català', command: () => setLocale('ca') },
  { label: 'Castellano', command: () => setLocale('es') },
  { label: 'English', command: () => setLocale('en') },
  { label: 'Русский', command: () => setLocale('ru') },
]

function toggleLang(event) {
  langMenu.value.toggle(event)
}

/* --- Menu --- */
const themeIcon = computed(() => currentTheme.value === 'dark' ? 'pi pi-sun' : 'pi pi-moon')

function isActive(path) {
  return route.path === path
}

const navItems = computed(() => {
  if (!auth.isAuthenticated) {
    return [
      { label: t('nav.login'), icon: 'pi pi-unlock', class: isActive('/') ? 'active-route' : '', command: () => router.push('/') },
      { label: t('nav.register'), icon: 'pi pi-user-plus', class: isActive('/Register') ? 'active-route' : '', command: () => router.push('/Register') },
    ]
  }

  const items = [
    { label: t('nav.home'), icon: 'pi pi-home', class: isActive('/Home') ? 'active-route' : '', command: () => router.push('/Home') },
    { label: t('nav.pokecuento'), icon: 'pi pi-youtube', class: isActive('/Pokecuento') ? 'active-route' : '', command: () => router.push('/Pokecuento') },
    { label: t('nav.pokefilm'), icon: 'pi pi-video', class: isActive('/Pokefilm') ? 'active-route' : '', command: () => router.push('/Pokefilm') },
  ]

  if (auth.isAdmin) {
    items.push({ label: t('nav.admin'), icon: 'pi pi-cog', class: isActive('/Admin') ? 'active-route' : '', command: () => router.push('/Admin') })
  }

  return items
})

function logout() {
  auth.logout().then(() => router.push('/'))
}
</script>

<template>
  <Menubar :model="navItems" breakpoint="0">
    <template #start>
      <div class="navbar-brand" @click="router.push('/Home')" tabindex="0" role="button">
        <img src="/Pokegrammys.ico" alt="" class="brand-icon" />
        <span class="brand-text">Pokegrammys</span>
      </div>
    </template>
    <template #end>
      <div class="navbar-actions">
        <Menu ref="langMenu" :model="langItems" popup />
        <Button icon="pi pi-globe" @click="toggleLang" text rounded class="nav-action-btn" />
        <Button :icon="themeIcon" @click="toggleTheme" text rounded class="nav-action-btn" />
        <Button
          v-if="auth.isAuthenticated"
          icon="pi pi-sign-out"
          @click="logout"
          text
          rounded
          class="nav-action-btn"
        />
      </div>
    </template>
  </Menubar>
  <router-view v-slot="{ Component }">
    <Transition name="page" mode="out-in">
      <component :is="Component" />
    </Transition>
  </router-view>
</template>
