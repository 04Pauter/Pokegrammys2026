<template>
  <div class="home-view" @mousemove="onMouseMove" ref="homeRef">
    <!-- Floating particles -->
    <div class="particles">
      <div
        v-for="p in particles"
        :key="p.id"
        class="particle"
        :style="{
          '--size': p.size + 'px',
          '--x': p.x + '%',
          '--y': p.y + '%',
          '--duration': p.duration + 's',
          '--delay': p.delay + 's',
          '--opacity': p.opacity
        }"
      />
    </div>

    <!-- Gradient orbs that follow mouse -->
    <div
      class="orb orb-gold"
      :style="{ transform: `translate(${orbGold.x}px, ${orbGold.y}px)` }"
    />
    <div
      class="orb orb-purple"
      :style="{ transform: `translate(${orbPurple.x}px, ${orbPurple.y}px)` }"
    />

    <!-- Main content -->
    <div class="home-content" :style="{ transform: `translate(${parallax.x}px, ${parallax.y}px)` }">
      <div class="badge">
        <span class="badge-dot" />
        {{ $t('home.year') || '2026' }}
      </div>
      <h1 class="hero-title">
        <span class="title-line title-line-1">Poke</span><span class="title-line title-line-2">grammys</span>
      </h1>
      <p class="hero-subtitle">{{ $t('home.subtitle') || 'Els millors Pokecuentos i Pokefilms de la comunitat' }}</p>
      <router-link to="/Pokecuento" class="cta-link cta-hero">
        <span class="cta-text">{{ $t('home.voteCta') }}</span>
        <span class="cta-arrow">→</span>
      </router-link>
    </div>

    <!-- Category cards -->
    <div class="home-categories">
      <router-link to="/Pokecuento" class="category-card">
        <div class="category-card-icon">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="2" y="7" width="20" height="15" rx="2" ry="2"/>
            <polyline points="17 2 12 7 7 2"/>
          </svg>
        </div>
        <h3>{{ $t('nav.pokecuento') }}</h3>
        <p>{{ $t('home.subtitle') || 'Els millors Pokecuentos de la comunitat' }}</p>
      </router-link>
      <router-link to="/Pokefilm" class="category-card">
        <div class="category-card-icon">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="2" y="2" width="20" height="20" rx="2.18" ry="2.18"/>
            <line x1="7" y1="2" x2="7" y2="22"/>
            <line x1="17" y1="2" x2="17" y2="22"/>
            <line x1="2" y1="12" x2="22" y2="12"/>
            <line x1="2" y1="7" x2="7" y2="7"/>
            <line x1="2" y1="17" x2="7" y2="17"/>
            <line x1="17" y1="7" x2="22" y2="7"/>
            <line x1="17" y1="17" x2="22" y2="17"/>
          </svg>
        </div>
        <h3>{{ $t('nav.pokefilm') }}</h3>
        <p>{{ $t('home.subtitle') || 'Els millors Pokefilms de la comunitat' }}</p>
      </router-link>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onUnmounted } from 'vue'

const homeRef = ref(null)

/* --- Particles --- */
const particles = Array.from({ length: 18 }, (_, i) => ({
  id: i,
  size: 2 + Math.random() * 5,
  x: Math.random() * 100,
  y: Math.random() * 100,
  duration: 8 + Math.random() * 16,
  delay: Math.random() * 8,
  opacity: 0.08 + Math.random() * 0.25
}))

/* --- Mouse tracking --- */
const parallax = reactive({ x: 0, y: 0 })
const orbGold = reactive({ x: 0, y: 0 })
const orbPurple = reactive({ x: 0, y: 0 })

function onMouseMove(e) {
  if (!homeRef.value) return
  const rect = homeRef.value.getBoundingClientRect()
  const cx = (e.clientX - rect.left) / rect.width - 0.5
  const cy = (e.clientY - rect.top) / rect.height - 0.5

  parallax.x = cx * -12
  parallax.y = cy * -12

  orbGold.x = cx * 40
  orbGold.y = cy * 40

  orbPurple.x = cx * -30
  orbPurple.y = cy * -30
}

onUnmounted(() => {
  if (homeRef.value) {
    homeRef.value.removeEventListener('mousemove', onMouseMove)
  }
})
</script>
