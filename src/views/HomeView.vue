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
    <div ref="orbGold" class="orb orb-gold" />
    <div ref="orbPurple" class="orb orb-purple" />

    <!-- Main content -->
    <div ref="contentRef" class="home-content">
      <div class="badge">
        <span class="badge-dot" />
        {{ $t('home.year') || '2026' }}
      </div>
      <h1 class="hero-title">
        <span class="title-line title-line-1">Poke</span><span class="title-line title-line-2">grammys</span>
      </h1>
      <p class="hero-subtitle">{{ $t('home.subtitle') || 'Els millors Pokecuentos i Pokefilms de la comunitat' }}</p>
      <router-link to="/Pokecuento" class="cta-link cta-hero">
        <span>{{ $t('home.voteCta') }}</span>
        <span class="cta-arrow" aria-hidden="true">→</span>
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
        <p>{{ $t('home.pokecuentoDesc') }}</p>
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
        <p>{{ $t('home.pokefilmDesc') }}</p>
      </router-link>
    </div>
  </div>
</template>

<script setup>
import { ref, onUnmounted } from 'vue'

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

/* --- Mouse tracking ---
   El parallax del contingut i el desplaçament dels orbes es
   calculen amb requestAnimationFrame i s'escriuen com a variables
   CSS: així no es reactivenitza el component a cada mousemove. */
const contentRef = ref(null)
const orbGold = ref(null)
const orbPurple = ref(null)

let raf = null
let pending = null

function flush() {
  raf = null
  if (!pending) return
  const { cx, cy } = pending

  if (contentRef.value) {
    contentRef.value.style.setProperty('--parallax-x', `${cx * -12}px`)
    contentRef.value.style.setProperty('--parallax-y', `${cy * -12}px`)
  }
  if (orbGold.value) {
    orbGold.value.style.setProperty('--orb-x', `${cx * 40}px`)
    orbGold.value.style.setProperty('--orb-y', `${cy * 40}px`)
  }
  if (orbPurple.value) {
    orbPurple.value.style.setProperty('--orb-x', `${cx * -30}px`)
    orbPurple.value.style.setProperty('--orb-y', `${cy * -30}px`)
  }
}

function onMouseMove(e) {
  const el = homeRef.value
  if (!el) return
  const rect = el.getBoundingClientRect()
  if (!rect.width || !rect.height) return
  pending = {
    cx: (e.clientX - rect.left) / rect.width - 0.5,
    cy: (e.clientY - rect.top) / rect.height - 0.5
  }
  if (raf === null) raf = requestAnimationFrame(flush)
}

onUnmounted(() => {
  if (raf !== null) cancelAnimationFrame(raf)
  raf = null
})
</script>
