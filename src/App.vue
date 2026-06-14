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

/* --- Menu --- */
function isActive(path) {
  return route.path === path
}

const themeIcon = computed(() => currentTheme.value === 'dark' ? 'pi pi-sun' : 'pi pi-moon')
const themeLabel = computed(() => currentTheme.value === 'dark' ? t('nav.lightMode') : t('nav.darkMode'))

const items = computed(() => {
  if (!auth.isAuthenticated) {
    return [
      { label: t('nav.login'), icon: 'pi pi-unlock', command: () => router.push('/') },
      { label: t('nav.register'), icon: 'pi pi-user-plus', command: () => router.push('/Register') },
      { separator: true },
      { label: t('nav.language'), icon: 'pi pi-globe', items: langItems },
      { label: themeLabel.value, icon: themeIcon.value, command: toggleTheme },
    ]
  }

  const authenticatedItems = [
    { label: t('nav.home'), icon: 'pi pi-home', class: isActive('/Home') ? 'active-route' : '', command: () => router.push('/Home') },
    { label: t('nav.pokecuento'), icon: 'pi pi-youtube', class: isActive('/Pokecuento') ? 'active-route' : '', command: () => router.push('/Pokecuento') },
    { label: t('nav.pokefilm'), icon: 'pi pi-video', class: isActive('/Pokefilm') ? 'active-route' : '', command: () => router.push('/Pokefilm') },
  ]

  if (auth.isAdmin) {
    authenticatedItems.push({ label: t('nav.admin'), icon: 'pi pi-cog', class: isActive('/Admin') ? 'active-route' : '', command: () => router.push('/Admin') })
  }

  authenticatedItems.push(
    { separator: true },
    { label: t('nav.language'), icon: 'pi pi-globe', items: langItems },
    { label: themeLabel.value, icon: themeIcon.value, command: toggleTheme },
    { label: t('nav.logout'), icon: 'pi pi-sign-out', command: () => auth.logout().then(() => router.push('/')) },
  )

  return authenticatedItems
})

function logout() {
  auth.logout().then(() => router.push('/'))
}
</script>

<template>
  <Menubar :model="items" breakpoint="0" />
  <router-view v-slot="{ Component }">
    <Transition name="page" mode="out-in">
      <component :is="Component" />
    </Transition>
  </router-view>
</template>
