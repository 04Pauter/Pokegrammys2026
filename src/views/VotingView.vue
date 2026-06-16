<template>
  <div class="voting-view" @mousemove="onMouseMove" ref="viewRef">
    <!-- Background ambient -->
    <div class="voting-particles">
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
    <div class="voting-noise" />
    <div
      class="orb orb-gold"
      :style="{ transform: `translate(${orbGold.x}px, ${orbGold.y}px)` }"
    />
    <div
      class="orb orb-purple"
      :style="{ transform: `translate(${orbPurple.x}px, ${orbPurple.y}px)` }"
    />

    <!-- Header -->
    <header class="page-header">
      <button class="back-btn" v-if="votingPhase === 'voting' && currentCategoryIndex > 0" @click="goBack">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
          <path d="M19 12H5M12 19l-7-7 7-7" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
        {{ $t('voting.back') }}
      </button>

      <div class="header-badge" v-if="votingPhase === 'voting'">
        <span class="badge-dot" />
        {{ typeLabel }}
      </div>
      <div class="voting-title-row">
        <img class="voting-title-icon" src="/Pokegrammys.ico" alt="" />
        <h1 class="voting-hero-title">Pokegrammys</h1>
      </div>
      <p class="subtitle">{{ $t('voting.byValery') }}</p>
    </header>

    <Transition name="state-fade" mode="out-in">
      <!-- LOADING -->
      <div v-if="loading" key="loading" class="loading-state">
        <div class="spinner"></div>
        <p>{{ $t('voting.loading') }}</p>
      </div>

      <!-- VOTING -->
      <div v-else-if="votingPhase === 'voting'" key="voting" class="voting-content">
        <!-- Progress Bar -->
        <div class="progress-section">
          <div class="progress-bar-container">
            <div class="progress-bar-bg">
              <div
                class="progress-bar-fill"
                :style="{ width: progressPercent + '%' }"
              />
              <div class="progress-bar-glow" :style="{ left: progressPercent + '%' }" />
            </div>
          </div>
          <div class="progress-info">
            <span class="progress-step-label">{{ currentCategoryIndex + 1 }} / {{ categories.length }}</span>
            <span class="progress-category-name">{{ currentCategory.nombre }}</span>
          </div>
        </div>

        <Transition name="state-fade" mode="out-in">
          <div v-if="errorMessage" key="error" class="error-message">{{ errorMessage }}</div>
        </Transition>

        <Transition name="category-slide" mode="out-in">
          <div :key="currentCategoryIndex" class="category-section">
            <div class="category-header">
              <div class="category-header-inner">
                <div class="category-accent-bar" />
                <h2>{{ currentCategory.nombre }}</h2>
                <span class="category-count">{{ nominees.length }} nominats</span>
              </div>
            </div>

            <div class="cards-grid">
              <VotingCard
                v-for="(item, index) in nominees"
                :key="item.id"
                :nominee="item"
                :selected="selectedNomineeId === item.id"
                :info-route-name="infoRouteName"
                :position="index + 1"
                @select="selectedNomineeId = item.id"
              />
            </div>
          </div>
        </Transition>

        <div class="vote-actions">
          <button
            class="vote-btn"
            :class="{ 'vote-btn-ready': selectedNomineeId }"
            :disabled="!selectedNomineeId"
            @click="submitVote"
          >
            <span class="vote-btn-text">
              {{ currentCategoryIndex === categories.length - 1 ? $t('voting.finish') : $t('voting.vote') }}
            </span>
            <span class="vote-btn-shine" />
            <svg v-if="selectedNomineeId" class="vote-btn-arrow" width="18" height="18" viewBox="0 0 24 24" fill="none">
              <path d="M5 12h14M12 5l7 7-7 7" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </button>
        </div>
      </div>

      <!-- DONE -->
      <div v-else-if="votingPhase === 'done'" key="done" class="done-state">
        <!-- Confetti -->
        <div class="confetti-container">
          <div v-for="c in confettiPieces" :key="c.id" class="confetti-piece" :style="confettiStyle(c)" />
        </div>

        <!-- Expanding rings -->
        <div class="done-rings">
          <div class="done-ring done-ring-1" />
          <div class="done-ring done-ring-2" />
          <div class="done-ring done-ring-3" />
        </div>

        <div class="done-icon-wrapper">
          <div class="done-icon">
            <img class="done-icon-img" src="/Pokegrammys.ico" alt="" />
          </div>
        </div>

        <h2 class="done-title">{{ $t('voting.completed') }}</h2>
        <p class="done-subtitle">{{ $t('voting.thanks', { year: new Date().getFullYear() }) }}</p>

        <router-link to="/Home" class="done-home-btn">
          <span>{{ $t('voting.backHome') || "Tornar a l'inici" }}</span>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
            <path d="M5 12h14M12 5l7 7-7 7" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </router-link>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, reactive, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '../lib/supabase.js'
import { useAuthStore } from '@/stores/auth.js'
import { Pokecuento } from '../models/Pokecuento.js'
import { Pokefilm } from '../models/Pokefilm.js'
import VotingCard from '../components/VotingCard.vue'

const props = defineProps({
  type: { type: String, required: true, validator: v => ['pokeserie', 'pokefilm'].includes(v) }
})

const { t } = useI18n()
const auth = useAuthStore()

const nominees = ref([])
const categories = ref([])
const currentCategoryIndex = ref(0)
const selectedNomineeId = ref(null)
const votes = ref([])
const loading = ref(true)
const votingPhase = ref('voting')
const errorMessage = ref('')

const tables = computed(() => ({
  categories: props.type === 'pokeserie' ? 'categorias_pokeserie' : 'categorias_pokefilm',
  nominados: props.type === 'pokeserie' ? 'nominados_pokeserie' : 'nominados_pokefilm',
  votacion: props.type === 'pokeserie' ? 'votacion_pokeserie' : 'votacion_pokefilm',
  foreignKey: props.type === 'pokeserie' ? 'pokecuento' : 'pokefilm',
  foreignKeyPlural: props.type === 'pokeserie' ? 'pokecuento_id' : 'pokefilm_id'
}))

const infoRouteName = computed(() => props.type === 'pokeserie' ? 'PokecuentoInfo' : 'PokefilmInfo')
const typeLabel = computed(() => props.type === 'pokeserie' ? 'Pokeserie' : 'Pokefilm')

const currentCategory = computed(() => categories.value[currentCategoryIndex.value])

const progressPercent = computed(() => {
  if (categories.value.length === 0) return 0
  return ((currentCategoryIndex.value + 1) / categories.value.length) * 100
})

async function loadCategory(index) {
  const category = categories.value[index]
  const { data, error } = await supabase
    .from(tables.value.nominados)
    .select(`*, ${tables.value.foreignKey}(*)`)
    .eq('categoria_id', category.id)

  if (error) {
    console.error('Error fetching nominees:', error)
    return
  }

  const Model = props.type === 'pokeserie' ? Pokecuento : Pokefilm
  nominees.value = data.map(item => new Model(item[tables.value.foreignKey]))
  selectedNomineeId.value = null
}

async function submitVote() {
  votes.value.push({
    categoria_id: currentCategory.value.id,
    nominee_id: selectedNomineeId.value
  })

  if (currentCategoryIndex.value < categories.value.length - 1) {
    currentCategoryIndex.value++
    await loadCategory(currentCategoryIndex.value)
  } else {
    await submitAllVotes()
  }
}

async function goBack() {
  votes.value.pop()
  currentCategoryIndex.value--
  await loadCategory(currentCategoryIndex.value)
  const lastVote = votes.value[votes.value.length - 1]
  if (lastVote) {
    selectedNomineeId.value = lastVote.nominee_id
  }
}

async function submitAllVotes() {
  if (!auth.user) {
    errorMessage.value = t('auth.loginRequired')
    return
  }

  const inserts = votes.value.map(v => ({
    votante_id: auth.user.id,
    categoria_id: v.categoria_id,
    [tables.value.foreignKeyPlural]: v.nominee_id
  }))

  errorMessage.value = ''

  const { error } = await supabase.from(tables.value.votacion).insert(inserts)

  if (error) {
    if (error.code === '23505') {
      errorMessage.value = t('voting.alreadyVoted')
    } else {
      errorMessage.value = t('voting.errorSending')
    }
    console.error('Error submitting votes:', error)
    return
  }

  votingPhase.value = 'done'
}

async function loadData() {
  loading.value = true
  votingPhase.value = 'voting'
  errorMessage.value = ''
  currentCategoryIndex.value = 0
  selectedNomineeId.value = null
  votes.value = []

  const { data: categoriesData, error: categoriesError } = await supabase
    .from(tables.value.categories)
    .select('*')
    .order('id')

  if (categoriesError) {
    console.error('Error fetching categories:', categoriesError)
    loading.value = false
    return
  }

  categories.value = categoriesData

  if (categoriesData.length > 0) {
    await loadCategory(0)
  }

  loading.value = false
}

onMounted(loadData)

watch(() => props.type, () => {
  loadData()
})

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

/* --- Confetti --- */
const confettiColors = ['#d4a843', '#f0cc6a', '#ffffff', '#c9a035', '#ffe082', '#8b5cf6', '#ec4899', '#06b6d4']
const confettiPieces = Array.from({ length: 75 }, (_, i) => ({
  id: i,
  x: 10 + Math.random() * 80,
  rotation: Math.random() * 360,
  scale: 0.4 + Math.random() * 0.9,
  delay: Math.random() * 0.8,
  duration: 2 + Math.random() * 2,
  drift: (Math.random() - 0.5) * 300,
  color: confettiColors[Math.floor(Math.random() * confettiColors.length)],
  shape: ['circle', 'rect', 'star'][Math.floor(Math.random() * 3)]
}))

function confettiStyle(c) {
  const shapeStyles = {
    circle: { width: '8px', height: '8px', borderRadius: '50%' },
    rect: { width: '6px', height: '12px', borderRadius: '2px' },
    star: { width: '10px', height: '10px', borderRadius: '2px', clipPath: 'polygon(50% 0%, 61% 35%, 98% 35%, 68% 57%, 79% 91%, 50% 70%, 21% 91%, 32% 57%, 2% 35%, 39% 35%)' }
  }
  return {
    left: c.x + '%',
    backgroundColor: c.color,
    ...shapeStyles[c.shape],
    transform: `rotate(${c.rotation}deg) scale(${c.scale})`,
    animationDelay: c.delay + 's',
    animationDuration: c.duration + 's',
    '--drift': c.drift + 'px'
  }
}
</script>
