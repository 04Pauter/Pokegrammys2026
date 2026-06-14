<script setup>
import { computed, ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth.js'
import Menubar from 'primevue/menubar'

const router = useRouter()
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

const languages = [
  { label: 'Català', command: () => setLocale('ca') },
  { separator: true },
  { label: 'Castellano', command: () => setLocale('es') },
  { separator: true },
  { label: 'English', command: () => setLocale('en') },
  { separator: true },
  { label: 'Русский', command: () => setLocale('ru') },
]

/* --- Menu --- */
const themeIcon = computed(() => currentTheme.value === 'dark' ? 'pi pi-sun' : 'pi pi-moon')
const themeLabel = computed(() => currentTheme.value === 'dark' ? t('nav.lightMode') : t('nav.darkMode'))

const items = computed(() => {
  if (!auth.isAuthenticated) {
    return [
      { label: t('nav.login'), icon: 'pi pi-unlock', command: () => router.push('/') },
      { label: t('nav.register'), icon: 'pi pi-user-plus', command: () => router.push('/Register') },
      { separator: true },
      { label: t('nav.language'), icon: 'pi pi-globe', items: languages },
      { label: themeLabel.value, icon: themeIcon.value, command: toggleTheme },
    ]
  }

  const menuItems = [
    { label: t('nav.home'), icon: 'pi pi-home', command: () => router.push('/Home') },
    { label: t('nav.pokecuento'), icon: 'pi pi-youtube', command: () => router.push('/Pokecuento') },
    { label: t('nav.pokefilm'), icon: 'pi pi-video', command: () => router.push('/Pokefilm') },
  ]

  if (auth.isAdmin) {
    menuItems.push({ label: t('nav.admin'), icon: 'pi pi-cog', command: () => router.push('/Admin') })
  }

  menuItems.push(
    { separator: true },
    { label: t('nav.language'), icon: 'pi pi-globe', items: languages },
    { label: themeLabel.value, icon: themeIcon.value, command: toggleTheme },
    { label: t('nav.logout'), icon: 'pi pi-sign-out', command: () => auth.logout().then(() => router.push('/')) },
  )

  return menuItems
})
</script>

<template>
  <Menubar :model="items" breakpoint="0" />
  <router-view v-slot="{ Component }">
    <Transition name="page" mode="out-in">
      <component :is="Component" />
    </Transition>
  </router-view>
</template>

