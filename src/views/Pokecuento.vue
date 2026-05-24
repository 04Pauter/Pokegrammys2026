<template>
  <div class="pokecuento-view">
    <header class="page-header">
      <h1>Pokegrammys</h1>
      <p class="subtitle">Por Valery Pokecuentos</p>
    </header>

    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>Carregant...</p>
    </div>

    <div v-else class="cards-grid">
      <PokecuentoCard v-for="item in pokecuentos" :key="item.id" :pokecuento="item" />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabase.js'
import { Pokecuento } from '../models/Pokecuento.js'
import PokecuentoCard from '../components/PokecuentoCard.vue'

const pokecuentos = ref([])
const loading = ref(true)

onMounted(async () => {
  const { data, error } = await supabase.from('pokecuento').select('*')
  if (error) {
    console.error('Error fetching pokecuentos:', error)
  } else {
    pokecuentos.value = data.map(item => new Pokecuento(item))
  }
  loading.value = false
})
</script>

<style>
.pokecuento-view {
  padding: 2rem;
  flex: 1;
}

.page-header {
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

.subtitle {
  font-size: 0.9rem;
  color: #c9a84c;
  margin: 0.35rem 0 0;
  font-weight: 600;
  letter-spacing: 0.15em;
  text-transform: uppercase;
}

.cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.5rem;
  max-width: 1200px;
  margin: 0 auto;
}

.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 4rem 0;
  color: #888;
  gap: 1rem;
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
