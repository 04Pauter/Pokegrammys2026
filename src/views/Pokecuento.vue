<template>
  <div class="pokecuento-view">
    <header class="page-header">
      <button class="back-btn" v-if="currentCategoryIndex > 0" @click="goBack">&larr; {{ $t('voting.back') }}</button>
      <h1>Pokegrammys</h1>
      <p class="subtitle">{{ $t('voting.byValery') }}</p>
    </header>

    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>{{ $t('voting.loading') }}</p>
    </div>

    <template v-else-if="votingPhase === 'voting'">
      <div class="progress-bar">
        <div class="progress-fill" :style="{ width: progressPercent + '%' }"></div>
      </div>
      <p class="progress-text">{{ $t('voting.categoryProgress', { n: currentCategoryIndex + 1, total: categories.length }) }}</p>

      <div v-if="errorMessage" class="error-message">{{ errorMessage }}</div>

      <div class="category-header">
        <h2>{{ currentCategory.nombre }}</h2>
      </div>

      <div class="cards-grid">
        <PokecuentoCard
          v-for="item in pokecuentos"
          :key="item.id"
          :pokecuento="item"
          :selected="selectedNomineeId === item.id"
          @select="selectedNomineeId = item.id"
        />
      </div>

      <div class="vote-actions">
        <button
          class="vote-btn"
          :disabled="!selectedNomineeId"
          @click="submitVote"
        >
          {{ currentCategoryIndex === categories.length - 1 ? $t('voting.finish') : $t('voting.vote') }}
        </button>
      </div>
    </template>

    <div v-else-if="votingPhase === 'done'" class="done-state">
      <div class="done-icon">&#10003;</div>
      <h2>{{ $t('voting.completed') }}</h2>
      <p>{{ $t('voting.thanks', { year: new Date().getFullYear() }) }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '../lib/supabase.js'
import { useAuthStore } from '@/stores/auth.js'
import { Pokecuento } from '../models/Pokecuento.js'
import PokecuentoCard from '../components/PokecuentoCard.vue'

const { t } = useI18n()

const auth = useAuthStore()

const pokecuentos = ref([])
const categories = ref([])
const currentCategoryIndex = ref(0)
const selectedNomineeId = ref(null)
const votes = ref([])
const loading = ref(true)
const votingPhase = ref('voting')
const errorMessage = ref('')

const currentCategory = computed(() => categories.value[currentCategoryIndex.value])
const progressPercent = computed(() =>
  categories.value.length
    ? ((currentCategoryIndex.value) / categories.value.length) * 100
    : 0
)

async function loadCategory(index) {
  const category = categories.value[index]
  const { data, error } = await supabase
    .from('nominados_pokeserie')
    .select('*, pokecuento(*)')
    .eq('categoria_id', category.id)

  if (error) {
    console.error('Error fetching nominees:', error)
    return
  }

  pokecuentos.value = data.map(item => new Pokecuento(item.pokecuento))
  selectedNomineeId.value = null
}

async function submitVote() {
  votes.value.push({
    categoria_id: currentCategory.value.id,
    pokecuento_id: selectedNomineeId.value
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
    selectedNomineeId.value = lastVote.pokecuento_id
  }
}

async function submitAllVotes() {
  const inserts = votes.value.map(v => ({
    votante_id: auth.user.id,
    categoria_id: v.categoria_id,
    pokecuento_id: v.pokecuento_id
  }))

  errorMessage.value = ''

  const { error } = await supabase.from('votacion_pokeserie').insert(inserts)

  if (error) {
    if (error.code === '23505') {
      errorMessage.value = t('voting.alreadyVoted')
    } else {
      errorMessage.value = t('voting.errorSending')
    }
    return
  }

  votingPhase.value = 'done'
}

onMounted(async () => {
  const { data: categoriesData, error: categoriesError } = await supabase
    .from('categorias_pokeserie')
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
})
</script>

<style>
</style>
