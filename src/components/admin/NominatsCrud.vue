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
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase.js'

const { t } = useI18n()

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

function config() {
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
    supabase.from(config().categories).select('*').order('id'),
    supabase.from(config().nominees).select('*').order('id'),
    supabase.from(config().nominats).select('*'),
  ])

  if (catRes.error) { error.value = catRes.error.message; return }
  if (nomRes.error) { error.value = nomRes.error.message; return }
  if (nomiRes.error) { error.value = nomiRes.error.message; return }

  categories.value = catRes.data ?? []
  nominees.value = nomRes.data ?? []
  nominations.value = (nomiRes.data ?? []).map(n => ({
    categoria_id: n[config().categoryKey],
    nominee_id: n[config().nomineeKey],
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
    [config().categoryKey]: selectedCategory.value,
    [config().nomineeKey]: selectedNominee.value,
  }
  const { error: err } = await supabase.from(config().nominats).insert(payload)
  if (err) {
    if (err.code === '23505') {
      error.value = t('admin.nominations.duplicate')
    } else {
      error.value = err.message
    }
  } else {
    selectedCategory.value = ''
    selectedNominee.value = ''
    await loadAll()
  }
}

async function removeNomination(categoriaId, nomineeId) {
  const { error: err } = await supabase
    .from(config().nominats)
    .delete()
    .eq(config().categoryKey, categoriaId)
    .eq(config().nomineeKey, nomineeId)
  if (err) {
    error.value = err.message
  } else {
    await loadAll()
  }
}

onMounted(loadAll)
</script>

