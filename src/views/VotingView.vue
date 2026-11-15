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
      ref="orbGold"
      class="orb orb-gold"
    />
    <div
      ref="orbPurple"
      class="orb orb-purple"
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
      <div v-else-if="votingPhase === 'voting' && currentCategory" key="voting" class="voting-content">
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
            <span class="progress-category-name">{{ $t('voting.nomineesCount', { count: nominees.length }) }}</span>
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
                <h2>{{ currentCategory?.nombre }}</h2>
              </div>
            </div>

            <div class="cards-grid" role="radiogroup" :aria-label="$t('nav.pokecuento')">
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
            :class="{ 'vote-btn-ready': selectedNomineeId && !submitting }"
            :disabled="!selectedNomineeId || submitting || nominees.length === 0"
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

      <!-- EMPTY -->
      <div v-else-if="emptyState" key="empty" class="loading-state empty-voting-state">
        <p>{{ $t('voting.noCategories') }}</p>
        <router-link to="/Home" class="done-home-btn">
          <span>{{ $t('voting.backHome') }}</span>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
            <path d="M5 12h14M12 5l7 7-7 7" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </router-link>
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
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
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
const submitting = ref(false)
const emptyState = ref(false)

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

/* --- Càrrega de dades ---------------------------------------
   `requestId` evita que dues càrregues solapades (canvi de
   pestanya ràpid) es barregin i deixin dades del tipus erroni. */
let requestId = 0

async function loadCategory(index) {
  const category = categories.value[index]
  if (!category) return

  // Es buiden els nominats i la selecció ABANS de la consulta:
  // si no, el títol nou apareixia damunt de les targetes velles.
  nominees.value = []
  selectedNomineeId.value = null

  const myRequest = requestId
  try {
    const { data, error } = await supabase
      .from(tables.value.nominados)
      .select(`*, ${tables.value.foreignKey}(*)`)
      .eq('categoria_id', category.id)

    if (myRequest !== requestId) return

    if (error) {
      console.error('Error fetching nominees:', error)
      errorMessage.value = t('voting.errorLoading')
      return
    }

    const Model = props.type === 'pokeserie' ? Pokecuento : Pokefilm
    nominees.value = (data || [])
      .filter(item => item[tables.value.foreignKey])
      .map(item => new Model(item[tables.value.foreignKey]))
  } catch (err) {
    if (myRequest !== requestId) return
    console.error('Error fetching nominees:', err)
    errorMessage.value = t('voting.errorLoading')
  }
}

async function submitVote() {
  if (submitting.value || !selectedNomineeId.value || !currentCategory.value) return

  submitting.value = true
  try {
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
  } finally {
    submitting.value = false
  }
}

async function goBack() {
  if (submitting.value || currentCategoryIndex.value <= 0) return
  submitting.value = true
  try {
    votes.value.pop()
    currentCategoryIndex.value--
    await loadCategory(currentCategoryIndex.value)
    const lastVote = votes.value[votes.value.length - 1]
    if (lastVote) {
      selectedNomineeId.value = lastVote.nominee_id
    }
  } finally {
    submitting.value = false
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
    /* Si el lot sencer falla (p. ex. per un vot d'una sessió anterior),
       provem fila a fila per no perdre cap vot: la restricció
       UNIQUE (votante_id, categoria_id) del servidor garanteix
       que cap categoria queda amb dos vots del mateix usuari. */
    if (error.code === '23505') {
      let saved = 0
      let duplicates = 0
      for (const row of inserts) {
        const { error: rowError } = await supabase.from(tables.value.votacion).insert(row)
        if (!rowError) {
          saved++
        } else if (rowError.code === '23505') {
          duplicates++
        } else {
          console.error('Error submitting vote:', rowError)
        }
      }

      if (saved > 0) {
        // Han triomfat els nous; els altres ja estaven desats.
        errorMessage.value = t('voting.partialVotes')
        votingPhase.value = 'done'
        return
      }

      if (duplicates === inserts.length) {
        errorMessage.value = t('voting.alreadyVoted')
        return
      }

      errorMessage.value = t('voting.errorSending')
      return
    }

    console.error('Error submitting votes:', error)
    errorMessage.value = t('voting.errorSending')
    return
  }

  votingPhase.value = 'done'
}

async function loadData() {
  const myRequest = ++requestId

  loading.value = true
  votingPhase.value = 'voting'
  errorMessage.value = ''
  currentCategoryIndex.value = 0
  selectedNomineeId.value = null
  votes.value = []
  nominees.value = []
  categories.value = []
  emptyState.value = false

  try {
    const { data: categoriesData, error: categoriesError } = await supabase
      .from(tables.value.categories)
      .select('*')
      .order('id')

    if (myRequest !== requestId) return

    if (categoriesError) {
      console.error('Error fetching categories:', categoriesError)
      errorMessage.value = t('voting.errorLoading')
      loading.value = false
      return
    }

    categories.value = categoriesData || []

    if (categories.value.length === 0) {
      emptyState.value = true
      loading.value = false
      return
    }

    await loadCategory(0)
  } catch (err) {
    if (myRequest !== requestId) return
    console.error('Error loading categories:', err)
    errorMessage.value = t('voting.errorLoading')
  } finally {
    if (myRequest === requestId) loading.value = false
  }
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

/* Els orbes segueixen el ratolí via variables CSS: s'escriuen
   directament al DOM, de manera que el component no es
   reactivenitza a cada mousemove. */
const orbGold = ref(null)
const orbPurple = ref(null)

let orbRaf = null
let orbPending = null

function flushOrbs() {
  orbRaf = null
  if (!orbPending) return
  const { x, y } = orbPending
  if (orbGold.value) {
    orbGold.value.style.setProperty('--orb-x', `${x * 30}px`)
    orbGold.value.style.setProperty('--orb-y', `${y * 30}px`)
  }
  if (orbPurple.value) {
    orbPurple.value.style.setProperty('--orb-x', `${x * -20}px`)
    orbPurple.value.style.setProperty('--orb-y', `${y * -20}px`)
  }
}

function onMouseMove(e) {
  const el = viewRef.value
  if (!el) return
  const rect = el.getBoundingClientRect()
  if (!rect.width || !rect.height) return
  orbPending = {
    x: (e.clientX - rect.left) / rect.width - 0.5,
    y: (e.clientY - rect.top) / rect.height - 0.5
  }
  if (orbRaf === null) orbRaf = requestAnimationFrame(flushOrbs)
}

onUnmounted(() => {
  if (orbRaf !== null) cancelAnimationFrame(orbRaf)
  orbRaf = null
})

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
    '--fall-duration': c.duration + 's',
    '--fall-delay': c.delay + 's',
    '--confetti-spin': (360 + c.rotation) + 'deg',
    '--confetti-scale': c.scale,
    '--drift': c.drift + 'px'
  }
}
</script>
