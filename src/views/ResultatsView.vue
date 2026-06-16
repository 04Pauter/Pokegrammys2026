<template>
  <div class="resultats-view" @mousemove="onMouseMove" ref="viewRef">
    <!-- Background ambient -->
    <div class="resultats-particles">
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
    <div class="resultats-noise" />
    <div class="orb orb-gold" :style="{ transform: `translate(${orbGold.x}px, ${orbGold.y}px)` }" />
    <div class="orb orb-purple" :style="{ transform: `translate(${orbPurple.x}px, ${orbPurple.y}px)` }" />

    <!-- Header -->
    <header class="page-header">
      <div class="header-badge">
        <span class="badge-dot" />
        {{ $t('results.badge') }}
      </div>
      <div class="voting-title-row">
        <img class="voting-title-icon" src="/Pokegrammys.ico" alt="" />
        <h1 class="voting-hero-title">Pokegrammys</h1>
      </div>
      <p class="subtitle">{{ $t('results.subtitle') }}</p>
    </header>

    <Transition name="state-fade" mode="out-in">
      <!-- LOADING -->
      <div v-if="loading" key="loading" class="loading-state">
        <div class="spinner"></div>
        <p>{{ $t('results.loading') }}</p>
      </div>

      <!-- CONTENT -->
      <div v-else key="content" class="results-content">
        <!-- Tabs -->
        <div class="tabs-row">
          <button
            class="tab-btn"
            :class="{ active: activeTab === 'pokeserie' }"
            @click="activeTab = 'pokeserie'"
          >
            <span class="tab-icon">📺</span>
            Pokeserie
          </button>
          <button
            class="tab-btn"
            :class="{ active: activeTab === 'pokefilm' }"
            @click="activeTab = 'pokefilm'"
          >
            <span class="tab-icon">🎬</span>
            Pokefilm
          </button>
        </div>

        <!-- Categories -->
        <Transition name="state-fade" mode="out-in">
          <div :key="activeTab" class="categories-list">
            <div
              v-for="(cat, catIdx) in currentResults"
              :key="cat.id"
              class="category-result-card"
              :style="{ animationDelay: catIdx * 0.1 + 's' }"
            >
              <div class="category-result-header">
                <div class="category-accent-bar" />
                <h2 class="category-result-name">{{ cat.nombre }}</h2>
                <span class="category-total-votes">{{ cat.totalVotos }} {{ $t('results.votes') }}</span>
              </div>

              <div class="category-result-body">
                <!-- Pie Chart + Legend -->
                <div class="pie-chart-wrapper">
                  <div class="pie-chart-container">
                    <div
                      class="pie-chart"
                      :style="{ background: cat.pieGradient }"
                    >
                      <div class="pie-glow" />
                      <div class="pie-center">
                        <span class="pie-center-number">{{ getAnimatedTotal(cat.id) }}</span>
                        <span class="pie-center-label">{{ $t('results.totalVotesLabel') }}</span>
                      </div>
                    </div>
                  </div>
                  <div class="pie-legend">
                    <div
                      v-for="(nom, i) in cat.nominees"
                      :key="nom.id"
                      class="legend-item"
                    >
                      <span class="legend-dot" :style="{ backgroundColor: pieColors[i % pieColors.length] }" />
                      <img v-if="nom.imagenurl" :src="nom.imagenurl" class="legend-thumb" :alt="nom.nombre" />
                      <span class="legend-label">{{ nom.nombre }}</span>
                      <span class="legend-percent">{{ nom.percent }}%</span>
                    </div>
                  </div>
                </div>

                <!-- Winner Spotlight + Progress bars -->
                <div class="nominees-right">
                  <!-- Winner Spotlight -->
                  <div v-if="cat.nominees.length > 0 && cat.totalVotos > 0" class="winner-spotlight">
                    <div class="winner-spotlight-inner">
                      <div class="winner-confetti">
                        <div v-for="c in winnerConfetti" :key="c.id" class="winner-confetti-piece" :style="winnerConfettiStyle(c)" />
                      </div>
                      <div class="winner-medal-wrapper">
                        <span class="winner-medal">🥇</span>
                      </div>
                      <div class="winner-image-wrapper">
                        <img :src="cat.nominees[0].imagenurl" class="winner-image" :alt="cat.nominees[0].nombre" />
                        <div class="winner-image-glow" />
                      </div>
                      <div class="winner-info">
                        <span class="winner-label">{{ $t('results.winner') }}</span>
                        <h3 class="winner-name">{{ cat.nominees[0].nombre }}</h3>
                        <p class="winner-author">{{ cat.nominees[0].autor }}</p>
                      </div>
                      <div class="winner-votes">
                        <span class="winner-votes-number">{{ cat.nominees[0].votos }}</span>
                        <span class="winner-votes-label">{{ $t('results.votes') }}</span>
                      </div>
                    </div>
                  </div>

                  <!-- Progress bars -->
                  <div class="nominees-bars">
                    <div
                      v-for="(nom, i) in cat.nominees"
                      :key="nom.id"
                      class="nominee-bar-row"
                      :class="{ winner: i === 0 && cat.totalVotos > 0 }"
                      :style="{ animationDelay: 0.3 + i * 0.1 + 's' }"
                    >
                      <div class="nominee-bar-info">
                        <div class="nominee-bar-left">
                          <span v-if="i < 3 && cat.totalVotos > 0" class="medal-icon" :class="'medal-' + (i + 1)">{{ getMedal(i) }}</span>
                          <img v-if="nom.imagenurl" :src="nom.imagenurl" class="nominee-thumb" :alt="nom.nombre" />
                          <span class="nominee-name">{{ nom.nombre }}</span>
                        </div>
                        <span class="nominee-percent">{{ nom.percent }}%</span>
                      </div>
                      <div class="bar-track">
                        <div
                          class="bar-fill"
                          :class="{ 'bar-winner': i === 0 && cat.totalVotos > 0 }"
                          :style="{
                            '--bar-width': nom.percent + '%',
                            '--bar-color': pieColors[i % pieColors.length],
                            animationDelay: 0.4 + i * 0.1 + 's'
                          }"
                        >
                          <div class="bar-fill-shimmer" />
                        </div>
                      </div>
                      <span class="nominee-votes">{{ nom.votos }} {{ $t('results.votes') }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div v-if="currentResults.length === 0" class="empty-state">
              <p>{{ $t('results.empty') }}</p>
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, reactive, watch, nextTick } from 'vue'
import { supabase } from '../lib/supabase.js'

const activeTab = ref('pokeserie')
const loading = ref(true)
const pokeserieResults = ref([])
const pokefilmResults = ref([])

/* --- Animated totals --- */
const animatedTotals = reactive({})

function getAnimatedTotal(catId) {
  return animatedTotals[catId] ?? 0
}

function animateCountUp(catId, target, duration = 1200) {
  const start = performance.now()
  const from = animatedTotals[catId] ?? 0
  function step(now) {
    const progress = Math.min((now - start) / duration, 1)
    const eased = 1 - Math.pow(1 - progress, 3)
    animatedTotals[catId] = Math.round(from + (target - from) * eased)
    if (progress < 1) requestAnimationFrame(step)
  }
  requestAnimationFrame(step)
}

function getMedal(index) {
  return ['🥇', '🥈', '🥉'][index] || ''
}

/* --- Pie Colors --- */
const pieColors = [
  '#d4a843', '#8b5cf6', '#06b6d4', '#ec4899',
  '#34d399', '#f97316', '#6366f1', '#ef4444',
  '#14b8a6', '#eab308', '#a855f7', '#3b82f6'
]

/* --- DB tables --- */
const tablesMap = {
  pokeserie: {
    categories: 'categorias_pokeserie',
    nominados: 'nominados_pokeserie',
    foreignKey: 'pokecuento',
    foreignKeyId: 'pokecuento_id',
  },
  pokefilm: {
    categories: 'categorias_pokefilm',
    nominados: 'nominados_pokefilm',
    foreignKey: 'pokefilm',
    foreignKeyId: 'pokefilm_id',
  }
}

const currentResults = computed(() =>
  activeTab.value === 'pokeserie' ? pokeserieResults.value : pokefilmResults.value
)

function buildPieGradient(nominees) {
  if (nominees.length === 0) return 'conic-gradient(var(--color-bg-card) 0deg 360deg)'
  const segments = []
  let currentDeg = 0
  nominees.forEach((nom, i) => {
    const deg = (nom.percent / 100) * 360
    segments.push(`${pieColors[i % pieColors.length]} ${currentDeg}deg ${currentDeg + deg}deg`)
    currentDeg += deg
  })
  return `conic-gradient(${segments.join(', ')})`
}

async function loadResults(type) {
  const t = tablesMap[type]

  const { data: categories, error: catErr } = await supabase
    .from(t.categories)
    .select('*')
    .order('id')

  if (catErr) {
    console.error('Error loading categories:', catErr)
    return
  }

  const { data: nominados, error: nomErr } = await supabase
    .from(t.nominados)
    .select(`*, ${t.foreignKey}(*)`)

  if (nomErr) {
    console.error('Error loading nominados:', nomErr)
    return
  }

  const rpcName = type === 'pokeserie' ? 'get_resultados_pokeserie' : 'get_resultados_pokefilm'
  const { data: results, error: resErr } = await supabase.rpc(rpcName)

  if (resErr) {
    console.error('Error loading results:', resErr)
    return
  }

  const resultsMap = {}
  for (const r of results) {
    const key = `${r.categoria_id}-${r[t.foreignKeyId]}`
    resultsMap[key] = r.votos
  }

  const enriched = categories.map(cat => {
    const catNominados = nominados
      .filter(n => n.categoria_id === cat.id)
      .map(n => {
        const item = n[t.foreignKey]
        const key = `${cat.id}-${item.id}`
        return {
          id: item.id,
          nombre: item.nombre,
          autor: item.autor,
          imagenurl: item.imagenurl,
          votos: resultsMap[key] || 0
        }
      })

    const totalVotos = catNominados.reduce((sum, n) => sum + n.votos, 0)
    const nominees = catNominados
      .map(n => ({
        ...n,
        percent: totalVotos > 0 ? Math.round((n.votos / totalVotos) * 100) : 0
      }))
      .sort((a, b) => b.votos - a.votos)

    return {
      id: cat.id,
      nombre: cat.nombre,
      totalVotos,
      nominees,
      pieGradient: buildPieGradient(nominees)
    }
  })

  if (type === 'pokeserie') {
    pokeserieResults.value = enriched
  } else {
    pokefilmResults.value = enriched
  }
}

async function loadAll() {
  loading.value = true
  await Promise.all([loadResults('pokeserie'), loadResults('pokefilm')])
  loading.value = false

  await nextTick()
  currentResults.value.forEach(cat => {
    animateCountUp(cat.id, cat.totalVotos)
  })
}

watch(activeTab, async (tab) => {
  if (tab === 'pokeserie' && pokeserieResults.value.length === 0) {
    await loadResults('pokeserie')
  } else if (tab === 'pokefilm' && pokefilmResults.value.length === 0) {
    await loadResults('pokefilm')
  }
  await nextTick()
  currentResults.value.forEach(cat => {
    animateCountUp(cat.id, cat.totalVotos)
  })
})

onMounted(loadAll)

/* --- Ambient particles --- */
const viewRef = ref(null)
const particles = Array.from({ length: 18 }, (_, i) => ({
  id: i,
  size: 2 + Math.random() * 5,
  x: Math.random() * 100,
  y: Math.random() * 100,
  duration: 10 + Math.random() * 18,
  delay: Math.random() * 6,
  opacity: 0.06 + Math.random() * 0.2
}))

const orbGold = reactive({ x: 0, y: 0 })
const orbPurple = reactive({ x: 0, y: 0 })

function onMouseMove(e) {
  if (!viewRef.value) return
  const rect = viewRef.value.getBoundingClientRect()
  const cx = (e.clientX - rect.left) / rect.width - 0.5
  const cy = (e.clientY - rect.top) / rect.height - 0.5
  orbGold.x = cx * 30
  orbGold.y = cy * 30
  orbPurple.x = cx * -20
  orbPurple.y = cy * -20
}

/* --- Winner Confetti --- */
const winnerConfettiColors = ['#d4a843', '#f0cc6a', '#ffffff', '#c9a035', '#ffe082', '#8b5cf6', '#ec4899', '#06b6d4']
const winnerConfetti = Array.from({ length: 20 }, (_, i) => ({
  id: i,
  x: 5 + Math.random() * 90,
  size: 4 + Math.random() * 6,
  delay: Math.random() * 2,
  duration: 2.5 + Math.random() * 2,
  drift: (Math.random() - 0.5) * 120,
  color: winnerConfettiColors[Math.floor(Math.random() * winnerConfettiColors.length)],
  rotation: Math.random() * 360
}))

function winnerConfettiStyle(c) {
  return {
    left: c.x + '%',
    width: c.size + 'px',
    height: c.size + 'px',
    backgroundColor: c.color,
    animationDelay: c.delay + 's',
    animationDuration: c.duration + 's',
    '--drift': c.drift + 'px',
    transform: `rotate(${c.rotation}deg)`
  }
}
</script>

<style scoped>
.resultats-view {
  min-height: 100vh;
  position: relative;
  overflow: hidden;
}

.resultats-view > *:not(.resultats-particles):not(.orb) {
  position: relative;
  z-index: 1;
}

/* --- Particles & Orbs --- */
.resultats-particles {
  position: fixed;
  inset: 0;
  pointer-events: none;
  z-index: 0;
}

.particle {
  position: absolute;
  width: var(--size);
  height: var(--size);
  background: var(--color-accent);
  border-radius: 50%;
  left: var(--x);
  top: var(--y);
  opacity: var(--opacity);
  animation: floatParticle var(--duration) var(--delay) ease-in-out infinite alternate;
}

@keyframes floatParticle {
  0% { transform: translateY(0) scale(1); }
  100% { transform: translateY(-30px) scale(1.3); }
}

.resultats-noise {
  position: fixed;
  inset: 0;
  pointer-events: none;
  z-index: 0;
  opacity: 0.03;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
  background-size: 128px;
}

.orb {
  position: fixed;
  width: 320px;
  height: 320px;
  border-radius: 50%;
  filter: blur(100px);
  pointer-events: none;
  z-index: 0;
  transition: transform 0.1s ease-out;
}

.orb-gold {
  top: 10%;
  left: 20%;
  background: radial-gradient(circle, rgba(212, 168, 67, 0.15) 0%, transparent 70%);
}

.orb-purple {
  bottom: 15%;
  right: 15%;
  background: radial-gradient(circle, rgba(139, 92, 246, 0.12) 0%, transparent 70%);
}

/* --- Header --- */
.page-header {
  text-align: center;
  padding: 3rem 1rem 1.5rem;
}

.header-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 6px 16px;
  border-radius: 999px;
  background: rgba(212, 168, 67, 0.1);
  border: 1px solid rgba(212, 168, 67, 0.25);
  color: var(--color-accent);
  font-size: 0.8rem;
  font-weight: 600;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  margin-bottom: 1rem;
}

.badge-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--color-accent);
  animation: pulse-dot 2s ease-in-out infinite;
}

@keyframes pulse-dot {
  0%, 100% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.5; transform: scale(1.4); }
}

.voting-title-row {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  margin-bottom: 0.5rem;
}

.voting-title-icon {
  width: 36px;
  height: 36px;
  border-radius: 8px;
}

.voting-hero-title {
  font-size: 2.5rem;
  font-weight: 800;
  background: linear-gradient(135deg, var(--color-accent) 0%, var(--color-accent-light) 50%, #ffffff 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  letter-spacing: -0.02em;
}

.subtitle {
  color: var(--color-text-muted);
  font-size: 0.95rem;
}

/* --- Loading --- */
.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  padding: 4rem 1rem;
  color: var(--color-text-muted);
}

.spinner {
  width: 36px;
  height: 36px;
  border: 3px solid var(--color-border);
  border-top-color: var(--color-accent);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* --- Tabs --- */
.tabs-row {
  display: flex;
  justify-content: center;
  gap: 8px;
  padding: 0 1rem 2rem;
}

.tab-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 24px;
  border: 1px solid var(--color-border);
  border-radius: 12px;
  background: var(--color-bg-card);
  color: var(--color-text-muted);
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
  transition: all var(--transition);
}

.tab-btn:hover {
  border-color: var(--color-border-hover);
  color: var(--color-text);
}

.tab-btn.active {
  background: rgba(212, 168, 67, 0.1);
  border-color: var(--color-accent);
  color: var(--color-accent);
  box-shadow: 0 0 20px rgba(212, 168, 67, 0.15);
}

.tab-icon {
  font-size: 1.1rem;
}

/* --- Results Content --- */
.results-content {
  max-width: 960px;
  margin: 0 auto;
  padding: 0 1rem 4rem;
}

/* --- Category Result Card --- */
.category-result-card {
  background: var(--color-bg-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  margin-bottom: 1.5rem;
  overflow: hidden;
  transition: border-color var(--transition), box-shadow var(--transition);
  animation: resultsCardEnter 0.6s cubic-bezier(0.16, 1, 0.3, 1) both;
}

.category-result-card:hover {
  border-color: var(--color-border-hover);
  box-shadow: var(--shadow-md), 0 0 30px rgba(212, 168, 67, 0.06);
}

@keyframes resultsCardEnter {
  from {
    opacity: 0;
    transform: translateY(24px) scale(0.97);
    filter: blur(4px);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
    filter: blur(0);
  }
}

.category-result-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 1.25rem 1.5rem;
  border-bottom: 1px solid var(--color-border);
  position: relative;
}

.category-accent-bar {
  width: 4px;
  height: 24px;
  border-radius: 2px;
  background: linear-gradient(180deg, var(--color-accent), var(--color-accent-light));
  flex-shrink: 0;
}

.category-result-name {
  font-size: 1.05rem;
  font-weight: 700;
  color: var(--color-text);
  flex: 1;
}

.category-total-votes {
  font-size: 0.8rem;
  color: var(--color-text-dim);
  background: var(--color-bg-input);
  padding: 4px 10px;
  border-radius: 999px;
  white-space: nowrap;
}

/* --- Body --- */
.category-result-body {
  display: grid;
  grid-template-columns: 240px 1fr;
  gap: 1.5rem;
  padding: 1.5rem;
  align-items: start;
}

/* --- Pie Chart --- */
.pie-chart-wrapper {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 14px;
}

.pie-chart-container {
  position: relative;
}

.pie-chart {
  width: 200px;
  height: 200px;
  border-radius: 50%;
  position: relative;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.3);
  animation: pieReveal 1s cubic-bezier(0.16, 1, 0.3, 1) both;
}

@keyframes pieReveal {
  from {
    transform: scale(0.6) rotate(-90deg);
    opacity: 0;
  }
  to {
    transform: scale(1) rotate(0deg);
    opacity: 1;
  }
}

.pie-glow {
  position: absolute;
  inset: -12px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(212, 168, 67, 0.15) 0%, transparent 70%);
  pointer-events: none;
  animation: pieGlowPulse 3s ease-in-out infinite alternate;
}

@keyframes pieGlowPulse {
  0% { opacity: 0.4; transform: scale(0.95); }
  100% { opacity: 0.8; transform: scale(1.05); }
}

.pie-center {
  position: absolute;
  inset: 24%;
  background: var(--color-bg-card);
  border-radius: 50%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  box-shadow: inset 0 2px 8px rgba(0, 0, 0, 0.2);
}

.pie-center-number {
  font-size: 1.6rem;
  font-weight: 800;
  color: var(--color-text);
  line-height: 1;
  animation: countReveal 0.6s ease 0.5s both;
}

@keyframes countReveal {
  from { opacity: 0; transform: scale(0.5); }
  to { opacity: 1; transform: scale(1); }
}

.pie-center-label {
  font-size: 0.55rem;
  color: var(--color-text-dim);
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin-top: 2px;
}

/* --- Pie Legend --- */
.pie-legend {
  display: flex;
  flex-direction: column;
  gap: 6px;
  width: 100%;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.75rem;
  color: var(--color-text-muted);
  overflow: hidden;
  padding: 4px 8px;
  border-radius: 6px;
  transition: background var(--transition);
}

.legend-item:hover {
  background: rgba(255, 255, 255, 0.04);
}

.legend-dot {
  width: 8px;
  height: 8px;
  border-radius: 2px;
  flex-shrink: 0;
}

.legend-thumb {
  width: 22px;
  height: 22px;
  border-radius: 4px;
  object-fit: cover;
  flex-shrink: 0;
  border: 1px solid var(--color-border);
}

.legend-label {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  flex: 1;
}

.legend-percent {
  font-weight: 700;
  color: var(--color-accent);
  font-size: 0.7rem;
  flex-shrink: 0;
}

/* --- Nominees Right Section --- */
.nominees-right {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

/* --- Winner Spotlight --- */
.winner-spotlight {
  position: relative;
  overflow: hidden;
  border-radius: var(--radius-lg);
  background: linear-gradient(135deg, rgba(212, 168, 67, 0.08) 0%, rgba(139, 92, 246, 0.04) 100%);
  border: 1px solid rgba(212, 168, 67, 0.2);
  animation: spotlightReveal 0.8s cubic-bezier(0.16, 1, 0.3, 1) 0.2s both;
}

@keyframes spotlightReveal {
  from {
    opacity: 0;
    transform: translateY(16px) scale(0.96);
    filter: blur(4px);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
    filter: blur(0);
  }
}

.winner-spotlight-inner {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.25rem;
  position: relative;
  z-index: 1;
}

.winner-confetti {
  position: absolute;
  inset: 0;
  pointer-events: none;
  overflow: hidden;
}

.winner-confetti-piece {
  position: absolute;
  top: -8px;
  border-radius: 2px;
  animation: winnerConfettiFall var(--duration, 2.5s) ease-in var(--delay, 0s) forwards;
}

@keyframes winnerConfettiFall {
  0% {
    transform: translateY(0) rotate(0deg) scale(1) translateX(0);
    opacity: 1;
  }
  50% {
    transform: translateY(40px) rotate(360deg) scale(0.8) translateX(var(--drift, 30px));
    opacity: 0.8;
  }
  100% {
    transform: translateY(80px) rotate(720deg) scale(0.3) translateX(calc(var(--drift, 30px) * -0.5));
    opacity: 0;
  }
}

.winner-medal-wrapper {
  position: relative;
  flex-shrink: 0;
}

.winner-medal {
  font-size: 2rem;
  display: block;
  animation: medalBounce 0.6s cubic-bezier(0.34, 1.56, 0.64, 1) 0.4s both;
}

@keyframes medalBounce {
  0% { transform: scale(0) rotate(-20deg); opacity: 0; }
  60% { transform: scale(1.2) rotate(5deg); opacity: 1; }
  100% { transform: scale(1) rotate(0deg); opacity: 1; }
}

.winner-image-wrapper {
  position: relative;
  flex-shrink: 0;
}

.winner-image {
  width: 72px;
  height: 72px;
  border-radius: 50%;
  object-fit: cover;
  border: 3px solid var(--color-accent);
  display: block;
  animation: winnerImagePop 0.5s cubic-bezier(0.34, 1.56, 0.64, 1) 0.3s both;
}

@keyframes winnerImagePop {
  0% { transform: scale(0.3); opacity: 0; }
  60% { transform: scale(1.1); }
  100% { transform: scale(1); opacity: 1; }
}

.winner-image-glow {
  position: absolute;
  inset: -8px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(212, 168, 67, 0.3) 0%, transparent 70%);
  pointer-events: none;
  animation: winnerGlowPulse 2s ease-in-out infinite alternate;
}

@keyframes winnerGlowPulse {
  0% { opacity: 0.5; transform: scale(0.9); }
  100% { opacity: 1; transform: scale(1.1); }
}

.winner-info {
  flex: 1;
  min-width: 0;
}

.winner-label {
  display: inline-block;
  font-size: 0.6rem;
  font-weight: 800;
  letter-spacing: 0.12em;
  color: var(--color-accent);
  background: rgba(212, 168, 67, 0.15);
  padding: 2px 8px;
  border-radius: 4px;
  margin-bottom: 4px;
}

.winner-name {
  font-size: 1.1rem;
  font-weight: 700;
  color: var(--color-text);
  margin: 0;
  line-height: 1.2;
}

.winner-author {
  font-size: 0.78rem;
  color: var(--color-text-muted);
  margin: 2px 0 0;
}

.winner-votes {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex-shrink: 0;
}

.winner-votes-number {
  font-size: 1.8rem;
  font-weight: 800;
  color: var(--color-accent);
  line-height: 1;
  animation: countReveal 0.6s ease 0.6s both;
}

.winner-votes-label {
  font-size: 0.6rem;
  color: var(--color-text-dim);
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

/* --- Progress Bars --- */
.nominees-bars {
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
}

.nominee-bar-row {
  display: flex;
  flex-direction: column;
  gap: 5px;
  opacity: 0;
  animation: barRowEnter 0.5s ease both;
}

@keyframes barRowEnter {
  from {
    opacity: 0;
    transform: translateX(20px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.nominee-bar-row.winner {
  position: relative;
}

.nominee-bar-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.nominee-bar-left {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}

.medal-icon {
  font-size: 0.85rem;
  flex-shrink: 0;
}

.medal-1 { animation: medalBounce 0.5s cubic-bezier(0.34, 1.56, 0.64, 1) 0.5s both; }
.medal-2 { animation: medalBounce 0.5s cubic-bezier(0.34, 1.56, 0.64, 1) 0.6s both; }
.medal-3 { animation: medalBounce 0.5s cubic-bezier(0.34, 1.56, 0.64, 1) 0.7s both; }

.nominee-thumb {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
  border: 2px solid var(--color-border);
  transition: border-color var(--transition), transform var(--transition);
}

.nominee-bar-row:hover .nominee-thumb {
  border-color: var(--color-accent);
  transform: scale(1.1);
}

.nominee-bar-row.winner .nominee-thumb {
  border-color: var(--color-accent);
}

.nominee-name {
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--color-text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.nominee-bar-row.winner .nominee-name {
  color: var(--color-accent);
  font-weight: 700;
}

.nominee-percent {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--color-accent);
  flex-shrink: 0;
}

.bar-track {
  width: 100%;
  height: 10px;
  background: var(--color-bg-input);
  border-radius: 5px;
  overflow: hidden;
}

.bar-fill {
  height: 100%;
  border-radius: 5px;
  position: relative;
  min-width: 2px;
  background: var(--bar-color);
  animation: barFill 1s cubic-bezier(0.16, 1, 0.3, 1) both;
}

@keyframes barFill {
  from { width: 0; }
  to { width: var(--bar-width); }
}

.bar-fill::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.2) 0%, transparent 60%);
  border-radius: inherit;
}

.bar-fill-shimmer {
  position: absolute;
  top: 0;
  left: -100%;
  width: 50%;
  height: 100%;
  background: linear-gradient(
    90deg,
    transparent 0%,
    rgba(255, 255, 255, 0.15) 50%,
    transparent 100%
  );
  animation: barShimmer 2.5s ease-in-out infinite;
}

@keyframes barShimmer {
  0% { left: -100%; }
  100% { left: 200%; }
}

.bar-winner {
  box-shadow: 0 0 12px rgba(212, 168, 67, 0.3);
}

.nominee-votes {
  font-size: 0.7rem;
  color: var(--color-text-dim);
}

/* --- Empty state --- */
.empty-state {
  text-align: center;
  padding: 4rem 1rem;
  color: var(--color-text-muted);
}

/* --- Transitions --- */
.state-fade-enter-active,
.state-fade-leave-active {
  transition: opacity 0.25s ease, transform 0.25s ease;
}
.state-fade-enter-from {
  opacity: 0;
  transform: translateY(10px);
}
.state-fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

/* --- Responsive --- */
@media (max-width: 640px) {
  .voting-hero-title {
    font-size: 1.8rem;
  }

  .category-result-body {
    grid-template-columns: 1fr;
    justify-items: center;
  }

  .pie-chart {
    width: 160px;
    height: 160px;
  }

  .pie-legend {
    flex-direction: row;
    flex-wrap: wrap;
    justify-content: center;
    gap: 8px;
  }

  .nominees-bars {
    width: 100%;
  }

  .tabs-row {
    flex-wrap: wrap;
  }

  .winner-spotlight-inner {
    flex-wrap: wrap;
    justify-content: center;
    text-align: center;
  }

  .winner-votes {
    width: 100%;
    flex-direction: row;
    justify-content: center;
    gap: 6px;
  }

  .winner-image {
    width: 60px;
    height: 60px;
  }
}
</style>
