<template>
  <div class="crud-section">
    <div class="crud-header">
      <h2>{{ $t('admin.nominations.title') }}</h2>
      <div class="tab-bar">
        <button :class="{ active: tab === 'pokeserie' }" @click="tab = 'pokeserie'">{{ $t('admin.nominations.tabPokeserie') }}</button>
        <button :class="{ active: tab === 'pokefilm' }" @click="tab = 'pokefilm'">{{ $t('admin.nominations.tabPokefilm') }}</button>
      </div>
    </div>

    <div class="nom-form">
      <select v-model="selectedCategory">
        <option value="" disabled>{{ $t('admin.nominations.selectCategory') }}</option>
        <option v-for="cat in categories" :key="cat.id" :value="cat.id">{{ cat.nombre }}</option>
      </select>
      <select v-model="selectedNominee">
        <option value="" disabled>{{ tab === 'pokeserie' ? $t('admin.nominations.selectPokecuento') : $t('admin.nominations.selectPokefilm') }}</option>
        <option v-for="nom in nominees" :key="nom.id" :value="nom.id">{{ nom.nombre }}</option>
      </select>
      <button @click="addNomination" :disabled="!selectedCategory || !selectedNominee">{{ $t('admin.nominations.add') }}</button>
    </div>

    <div v-if="error" class="error-msg">{{ error }}</div>

    <table v-if="nominations.length" class="crud-table">
      <thead>
        <tr>
          <th>{{ $t('admin.nominations.category') }}</th>
          <th>{{ tab === 'pokeserie' ? $t('admin.nominations.selectPokecuento') : $t('admin.nominations.selectPokefilm') }}</th>
          <th>{{ $t('admin.nominations.actions') }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(nom, i) in nominations" :key="i">
          <td>{{ categoryName(nom.categoria_id) }}</td>
          <td>{{ nomineeName(nom.nominee_id) }}</td>
          <td class="actions">
            <button class="btn-danger" @click="removeNomination(nom.categoria_id, nom.nominee_id)">{{ $t('admin.nominations.delete') }}</button>
          </td>
        </tr>
      </tbody>
    </table>
    <p v-else class="empty">{{ $t('admin.nominations.empty') }}</p>
  </div>
</template>

<script setup>
import { ref, watch, onMounted, computed } from 'vue'
import { supabase } from '@/lib/supabase.js'

const TABLES = {
  pokeserie: {
    nominats: 'nominados_pokeserie',
    categories: 'categorias_pokeserie',
    nominees: 'pokecuento',
    categoryKey: 'categoria_id',
    nomineeKey: 'pokecuento_id',
  },
  pokefilm: {
    nominats: 'nominados_pokefilm',
    categories: 'categorias_pokefilm',
    nominees: 'pokefilm',
    categoryKey: 'categoria_id',
    nomineeKey: 'pokefilm_id',
  },
}

const tab = ref('pokeserie')
const categories = ref([])
const nominees = ref([])
const nominations = ref([])
const selectedCategory = ref('')
const selectedNominee = ref('')
const error = ref('')

const catMap = computed(() => {
  const m = {}
  for (const c of categories.value) m[c.id] = c.nombre
  return m
})

const nomMap = computed(() => {
  const m = {}
  for (const n of nominees.value) m[n.id] = n.nombre
  return m
})

function t() {
  return TABLES[tab.value]
}

function categoryName(id) {
  return catMap.value[id] ?? id
}

function nomineeName(id) {
  return nomMap.value[id] ?? id
}

async function loadAll() {
  const [catRes, nomRes, nomiRes] = await Promise.all([
    supabase.from(t().categories).select('*').order('id'),
    supabase.from(t().nominees).select('*').order('id'),
    supabase.from(t().nominats).select('*'),
  ])

  if (catRes.error) { error.value = catRes.error.message; return }
  if (nomRes.error) { error.value = nomRes.error.message; return }
  if (nomiRes.error) { error.value = nomiRes.error.message; return }

  categories.value = catRes.data ?? []
  nominees.value = nomRes.data ?? []
  nominations.value = (nomiRes.data ?? []).map(n => ({
    categoria_id: n[t().categoryKey],
    nominee_id: n[t().nomineeKey],
  }))
}

watch(tab, () => {
  selectedCategory.value = ''
  selectedNominee.value = ''
  error.value = ''
  loadAll()
})

async function addNomination() {
  error.value = ''
  const payload = {
    [t().categoryKey]: selectedCategory.value,
    [t().nomineeKey]: selectedNominee.value,
  }
  const { error: err } = await supabase.from(t().nominats).insert(payload)
  if (err) {
    error.value = err.message
  } else {
    selectedCategory.value = ''
    selectedNominee.value = ''
    await loadAll()
  }
}

async function removeNomination(categoriaId, nomineeId) {
  const { error: err } = await supabase
    .from(t().nominats)
    .delete()
    .eq(t().categoryKey, categoriaId)
    .eq(t().nomineeKey, nomineeId)
  if (err) {
    error.value = err.message
  } else {
    await loadAll()
  }
}

onMounted(loadAll)
</script>

<style scoped>
.nom-form {
  display: flex;
  gap: 0.75rem;
  align-items: center;
  justify-content: center;
  margin-bottom: 1rem;
  flex-wrap: wrap;
}

.nom-form select {
  max-width: 320px;
}

.nom-form button {
  white-space: nowrap;
}
</style>
