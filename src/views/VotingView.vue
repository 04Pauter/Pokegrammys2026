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
        &larr; {{ $t('voting.back') }}
      </button>
      <div class="header-badge" v-if="votingPhase === 'voting'">
        <span class="badge-dot" />
        {{ typeLabel }}
      </div>
      <h1 class="voting-hero-title">
        <span class="title-line">Poke</span><span class="title-line title-line-sub">grammys</span>
      </h1>
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
        <!-- Progress Steps -->
        <div class="progress-steps">
          <div
            v-for="(cat, i) in categories"
            :key="cat.id"
            class="step-wrapper"
          >
            <div
              class="step-dot"
              :class="{
                completed: i < currentCategoryIndex,
                active: i === currentCategoryIndex,
                pending: i > currentCategoryIndex
              }"
            >
              <svg v-if="i < currentCategoryIndex" class="step-check" width="14" height="14" viewBox="0 0 24 24" fill="none">
                <path d="M5 13l4 4L19 7" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
              <span v-else class="step-number">{{ i + 1 }}</span>
            </div>
            <div v-if="i < categories.length - 1" class="step-connector">
              <div class="step-connector-fill" :class="{ filled: i < currentCategoryIndex }" />
            </div>
          </div>
        </div>
        <p class="progress-text">{{ $t('voting.categoryProgress', { n: currentCategoryIndex + 1, total: categories.length }) }}</p>

        <Transition name="state-fade" mode="out-in">
          <div v-if="errorMessage" key="error" class="error-message">{{ errorMessage }}</div>
        </Transition>

        <Transition name="category-slide" mode="out-in">
          <div :key="currentCategoryIndex" class="category-section">
            <div class="category-header">
              <div class="category-accent-bar" />
              <h2>{{ currentCategory.nombre }}</h2>
            </div>

            <div class="cards-grid">
              <VotingCard
                v-for="item in nominees"
                :key="item.id"
                :nominee="item"
                :selected="selectedNomineeId === item.id"
                :info-route-name="infoRouteName"
                @select="selectedNomineeId = item.id"
              />
            </div>
          </div>
        </Transition>

        <div class="vote-actions">
          <button
            class="vote-btn"
            :disabled="!selectedNomineeId"
            @click="submitVote"
          >
            <span class="vote-btn-text">
              {{ currentCategoryIndex === categories.length - 1 ? $t('voting.finish') : $t('voting.vote') }}
            </span>
            <span class="vote-btn-shine" />
          </button>
        </div>
      </div>

      <!-- DONE -->
      <div v-else-if="votingPhase === 'done'" key="done" class="done-state">
        <!-- Confetti -->
        <div class="confetti-container">
          <div v-for="c in confettiPieces" :key="c.id" class="confetti-piece" :style="confettiStyle(c)" />
        </div>

        <div class="done-icon-wrapper">
          <div class="done-ring done-ring-outer" />
          <div class="done-ring done-ring-inner" />
          <div class="done-icon">
            <svg width="36" height="36" viewBox="0 0 24 24" fill="none">
              <path d="M5 13l4 4L19 7" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </div>
        </div>
        <h2 class="done-title">{{ $t('voting.completed') }}</h2>
        <p class="done-subtitle">{{ $t('voting.thanks', { year: new Date().getFullYear() }) }}</p>
        <router-link to="/Home" class="done-home-btn">
          {{ $t('voting.backHome') || "Tornar a l'inici" }}
          <span class="cta-arrow">→</span>
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
const particles = Array.from({ length: 14 }, (_, i) => ({
  id: i,
  size: 2 + Math.random() * 4,
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
const confettiPieces = Array.from({ length: 50 }, (_, i) => ({
  id: i,
  x: 40 + Math.random() * 20,
  rotation: Math.random() * 360,
  scale: 0.5 + Math.random() * 0.8,
  delay: Math.random() * 0.6,
  duration: 1.8 + Math.random() * 1.5,
  drift: (Math.random() - 0.5) * 200,
  color: ['#d4a843', '#f0cc6a', '#ffffff', '#c9a035', '#ffe082'][Math.floor(Math.random() * 5)],
  shape: Math.random() > 0.5 ? 'circle' : 'rect'
}))

function confettiStyle(c) {
  return {
    left: c.x + '%',
    backgroundColor: c.color,
    width: c.shape === 'circle' ? '8px' : '6px',
    height: c.shape === 'circle' ? '8px' : '10px',
    borderRadius: c.shape === 'circle' ? '50%' : '2px',
    transform: `rotate(${c.rotation}deg) scale(${c.scale})`,
    animationDelay: c.delay + 's',
    animationDuration: c.duration + 's',
    '--drift': c.drift + 'px'
  }
}
</script>
