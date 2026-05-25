<template>
  <div class="pokefilm-view">
    <header class="page-header">
      <button class="back-btn" v-if="currentCategoryIndex > 0" @click="goBack">&larr; Anterior</button>
      <h1>Pokegrammys</h1>
      <p class="subtitle">Por Valery Pokecuentos</p>
    </header>

    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>Carregant...</p>
    </div>

    <template v-else-if="votingPhase === 'voting'">
      <div class="progress-bar">
        <div class="progress-fill" :style="{ width: progressPercent + '%' }"></div>
      </div>
      <p class="progress-text">Categoria {{ currentCategoryIndex + 1 }} de {{ categories.length }}</p>

      <div v-if="errorMessage" class="error-message">{{ errorMessage }}</div>

      <div class="category-header">
        <h2>{{ currentCategory.nombre }}</h2>
      </div>

      <div class="cards-grid">
        <PokefilmCard
          v-for="item in pokefilms"
          :key="item.id"
          :pokefilm="item"
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
          {{ currentCategoryIndex === categories.length - 1 ? 'Finalitzar' : 'Votar' }}
        </button>
      </div>
    </template>

    <div v-else-if="votingPhase === 'done'" class="done-state">
      <div class="done-icon">&#10003;</div>
      <h2>Votació completada!</h2>
      <p>Gràcies per votar als Pokegrammys {{ new Date().getFullYear() }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../lib/supabase.js'
import { useAuthStore } from '@/stores/auth.js'
import { Pokefilm } from '../models/Pokefilm.js'
import PokefilmCard from '../components/PokefilmCard.vue'


const auth = useAuthStore()

const pokefilms = ref([])
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
    .from('nominados_pokefilm')
    .select('*, pokefilm(*)')
    .eq('categoria_id', category.id)

  if (error) {
    console.error('Error fetching nominees:', error)
    return
  }

  pokefilms.value = data.map(item => new Pokefilm(item.pokefilm))
  selectedNomineeId.value = null
}

async function submitVote() {
  votes.value.push({
    categoria_id: currentCategory.value.id,
    pokefilm_id: selectedNomineeId.value
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
    selectedNomineeId.value = lastVote.pokefilm_id
  }
}

async function submitAllVotes() {
  const inserts = votes.value.map(v => ({
    votante_id: auth.user.id,
    categoria_id: v.categoria_id,
    pokefilm_id: v.pokefilm_id
  }))

  errorMessage.value = ''

  const { error } = await supabase.from('votacion_pokefilm').insert(inserts)

  if (error) {
    errorMessage.value = 'Error al enviar los votos. \n';
    if (error.code = '23505'){
     errorMessage.value += 'Ya has votado anteriormente'; 
    }
    console.error('Error submitting votes:', error)
    return
  }

  votingPhase.value = 'done'
}

onMounted(async () => {
  const { data: categoriesData, error: categoriesError } = await supabase
    .from('categorias_pokefilm')
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
.pokefilm-view {
  padding: 2rem;
  flex: 1;
}

.page-header {
  position: relative;
  text-align: center;
  margin-bottom: 2.5rem;
}

.page-header h1 {
  font-size: 2.5rem;
  font-weight: 800;
  color: #ffffff;
  margin: 0;
  letter-spacing: -0.02em;
  text-transform: uppercase;
}

.back-btn {
  position: absolute;
  left: 2rem;
  top: 2rem;
  background: none;
  border: 1px solid #2a2a35;
  color: #c9a84c;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.9rem;
  font-weight: 600;
  transition: border-color 0.2s, color 0.2s;
}

.back-btn:hover {
  border-color: #c9a84c;
  color: #ffffff;
}

.subtitle {
  font-size: 0.9rem;
  color: #c9a84c;
  margin: 0.35rem 0 0;
  font-weight: 600;
  letter-spacing: 0.15em;
  text-transform: uppercase;
}

.progress-bar {
  width: 100%;
  max-width: 600px;
  height: 6px;
  background: #2a2a35;
  border-radius: 3px;
  margin: 0 auto 0.5rem;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: #c9a84c;
  border-radius: 3px;
  transition: width 0.3s ease;
}

.progress-text {
  text-align: center;
  color: #888;
  font-size: 0.85rem;
  margin: 0 0 2rem;
}

.category-header {
  text-align: center;
  margin-bottom: 2rem;
}

.category-header h2 {
  font-size: 1.5rem;
  font-weight: 700;
  color: #ffffff;
  margin: 0;
}

.cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.5rem;
  max-width: 1200px;
  margin: 0 auto;
}

.vote-actions {
  display: flex;
  justify-content: center;
  margin-top: 2.5rem;
}

.vote-btn {
  padding: 0.85rem 3rem;
  font-size: 1.1rem;
  font-weight: 700;
  color: #16161e;
  background: #c9a84c;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  transition: opacity 0.2s, transform 0.15s;
}

.vote-btn:hover:not(:disabled) {
  opacity: 0.9;
  transform: translateY(-2px);
}

.vote-btn:disabled {
  opacity: 0.35;
  cursor: not-allowed;
}

.loading-state,
.done-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 4rem 0;
  color: #888;
  gap: 1rem;
}

.done-icon {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  background: #c9a84c;
  color: #16161e;
  font-size: 2rem;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
}

.done-state h2 {
  color: #ffffff;
  margin: 0;
  font-size: 1.5rem;
}

.done-state p {
  margin: 0;
  color: #888;
}

.error-message {
  max-width: 600px;
  margin: 0 auto 1.5rem;
  padding: 0.75rem 1rem;
  background: #2d1515;
  border: 1px solid #e74c3c;
  border-radius: 8px;
  color: #e74c3c;
  text-align: center;
  font-size: 0.9rem;
  font-weight: 600;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid #2a2a35;
  border-top-color: #c9a84c;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
