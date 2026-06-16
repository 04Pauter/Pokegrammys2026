<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth.js'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()
const { t, locale } = useI18n()

/* --- Theme --- */
const currentTheme = ref('dark')
const themeAnimating = ref(false)

function getSystemTheme() {
  return window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark'
}

function applyTheme(theme) {
  currentTheme.value = theme
  document.documentElement.setAttribute('data-theme', theme)
  localStorage.setItem('pokegrammys-theme', theme)
}

function toggleTheme() {
  themeAnimating.value = true
  applyTheme(currentTheme.value === 'dark' ? 'light' : 'dark')
  setTimeout(() => { themeAnimating.value = false }, 400)
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
const locales = [
  { code: 'ca', label: 'Català', flagSvg: '<svg width="20" height="14" viewBox="0 0 20 14" xmlns="http://www.w3.org/2000/svg"><rect width="20" height="14" rx="2" fill="#FCDD09"/><rect y="0" width="20" height="2" fill="#DA291C"/><rect y="4" width="20" height="2" fill="#DA291C"/><rect y="8" width="20" height="2" fill="#DA291C"/><rect y="12" width="20" height="2" fill="#DA291C"/></svg>' },
  { code: 'es', label: 'Castellano', flag: '🇪🇸' },
  { code: 'en', label: 'English', flag: '🇬🇧' },
  { code: 'ru', label: 'Русский', flag: '🇷🇺' },
]

const showLangDropdown = ref(false)
const langDropdownRef = ref(null)

const currentLocale = computed(() => locales.find(l => l.code === locale.value) || locales[0])

function setLocale(code) {
  locale.value = code
  localStorage.setItem('locale', code)
  showLangDropdown.value = false
}

function toggleLangDropdown() {
  showLangDropdown.value = !showLangDropdown.value
}

function handleClickOutside(e) {
  if (langDropdownRef.value && !langDropdownRef.value.contains(e.target)) {
    showLangDropdown.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})

/* --- Navigation --- */
function isActive(path) {
  return route.path === path
}

const navLinks = computed(() => {
  const links = [
    { label: t('nav.home'), path: '/Home', icon: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-4 0a1 1 0 01-1-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 01-1 1' },
  ]

  if (auth.isAuthenticated) {
    links.push(
      { label: t('nav.pokecuento'), path: '/Pokecuento', icon: 'M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z' },
      { label: t('nav.pokefilm'), path: '/Pokefilm', icon: 'M7 4v16M17 4v16M3 8h4m10 0h4M3 12h18M3 16h4m10 0h4M4 20h16a1 1 0 001-1V5a1 1 0 00-1-1H4a1 1 0 00-1 1v14a1 1 0 001 1z' },
    )
  }

  if (auth.isAdmin) {
    links.push({ label: t('nav.admin'), path: '/Admin', icon: 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z M15 12a3 3 0 11-6 0 3 3 0 016 0z' })
  }

  return links
})

/* --- Mobile menu --- */
const mobileMenuOpen = ref(false)

function toggleMobileMenu() {
  mobileMenuOpen.value = !mobileMenuOpen.value
}

function closeMobileMenu() {
  mobileMenuOpen.value = false
}
</script>

<template>
  <nav class="navbar">
    <div class="navbar-left">
      <!-- Brand -->
      <div class="navbar-brand" @click="router.push('/Home')">
        <img class="brand-icon" src="/Pokegrammys.ico" alt="Pokegrammys" />
        <span class="brand-text">Pokegrammys</span>
      </div>

      <!-- Navigation links (desktop) -->
      <div class="navbar-nav desktop-only">
        <router-link
          v-for="link in navLinks"
          :key="link.path"
          :to="link.path"
          class="nav-link"
          :class="{ active: isActive(link.path) }"
        >
          <svg class="nav-link-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path :d="link.icon"/>
          </svg>
          <span>{{ link.label }}</span>
        </router-link>
      </div>
    </div>

    <div class="navbar-right">
      <!-- Language selector -->
      <div class="nav-dropdown" ref="langDropdownRef">
        <button class="nav-action-btn" @click.stop="toggleLangDropdown" :title="t('nav.language')">
          <span class="lang-flag" v-if="currentLocale.flagSvg" v-html="currentLocale.flagSvg"></span>
          <span class="lang-flag" v-else>{{ currentLocale.flag }}</span>
          <span class="lang-code desktop-only">{{ currentLocale.code.toUpperCase() }}</span>
          <svg class="dropdown-arrow" :class="{ open: showLangDropdown }" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <path d="M6 9l6 6 6-6"/>
          </svg>
        </button>
        <Transition name="dropdown">
          <div v-if="showLangDropdown" class="dropdown-menu lang-dropdown">
            <button
              v-for="loc in locales"
              :key="loc.code"
              class="dropdown-item"
              :class="{ active: locale === loc.code }"
              @click="setLocale(loc.code)"
            >
              <span class="dropdown-item-flag" v-if="loc.flagSvg" v-html="loc.flagSvg"></span>
              <span class="dropdown-item-flag" v-else>{{ loc.flag }}</span>
              <span class="dropdown-item-label">{{ loc.label }}</span>
              <svg v-if="locale === loc.code" class="dropdown-check" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
                <path d="M5 13l4 4L19 7"/>
              </svg>
            </button>
          </div>
        </Transition>
      </div>

      <!-- Theme toggle -->
      <button class="nav-action-btn theme-toggle" @click="toggleTheme" :class="{ animating: themeAnimating }">
        <Transition name="theme-icon" mode="out-in">
          <svg v-if="currentTheme === 'dark'" key="sun" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="5"/>
            <line x1="12" y1="1" x2="12" y2="3"/>
            <line x1="12" y1="21" x2="12" y2="23"/>
            <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/>
            <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
            <line x1="1" y1="12" x2="3" y2="12"/>
            <line x1="21" y1="12" x2="23" y2="12"/>
            <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/>
            <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
          </svg>
          <svg v-else key="moon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
          </svg>
        </Transition>
      </button>

      <!-- Logout (only when authenticated) -->
      <button v-if="auth.isAuthenticated" class="nav-action-btn logout-btn" @click="auth.logout().then(() => router.push('/'))" :title="t('nav.logout')">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
          <polyline points="16 17 21 12 16 7"/>
          <line x1="21" y1="12" x2="9" y2="12"/>
        </svg>
      </button>

      <!-- Login/Register (when not authenticated) -->
      <template v-if="!auth.isAuthenticated">
        <router-link to="/" class="nav-action-btn login-btn">
          <span class="desktop-only">{{ t('nav.login') }}</span>
          <svg class="mobile-only" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/>
            <polyline points="10 17 15 12 10 7"/>
            <line x1="15" y1="12" x2="3" y2="12"/>
          </svg>
        </router-link>
        <router-link to="/Register" class="nav-action-btn register-btn desktop-only">
          {{ t('nav.register') }}
        </router-link>
      </template>

      <!-- Mobile hamburger -->
      <button class="nav-action-btn hamburger mobile-only" @click="toggleMobileMenu" :class="{ open: mobileMenuOpen }">
        <span></span>
        <span></span>
        <span></span>
      </button>
    </div>
  </nav>

  <!-- Mobile menu overlay -->
  <Transition name="mobile-menu">
    <div v-if="mobileMenuOpen" class="mobile-menu-overlay" @click="closeMobileMenu">
      <div class="mobile-menu" @click.stop>
        <router-link
          v-for="link in navLinks"
          :key="link.path"
          :to="link.path"
          class="mobile-nav-link"
          :class="{ active: isActive(link.path) }"
          @click="closeMobileMenu"
        >
          <svg class="mobile-nav-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path :d="link.icon"/>
          </svg>
          <span>{{ link.label }}</span>
        </router-link>
      </div>
    </div>
  </Transition>

  <router-view v-slot="{ Component }">
    <Transition name="page" mode="out-in">
      <component :is="Component" />
    </Transition>
  </router-view>
</template>
