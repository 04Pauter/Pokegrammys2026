<template>
  <div class="crud-section">
    <div class="crud-header">
      <h2>{{ $t('admin.categories.title') }}</h2>
      <div class="tab-bar">
        <button :class="{ active: tab === 'pokeserie' }" @click="tab = 'pokeserie'">{{ $t('admin.categories.tabPokeserie') }}</button>
        <button :class="{ active: tab === 'pokefilm' }" @click="tab = 'pokefilm'">{{ $t('admin.categories.tabPokefilm') }}</button>
      </div>
      <button @click="openCreate">{{ $t('admin.categories.new') }}</button>
    </div>

    <div v-if="showForm" class="crud-form">
      <h3>{{ editing ? $t('admin.categories.editTitle') : $t('admin.categories.newTitle') }}</h3>
      <form @submit.prevent="save">
        <input v-model="form.nombre" :placeholder="$t('admin.categories.namePlaceholder')" required />
        <div class="form-actions">
          <button type="submit">{{ editing ? $t('admin.categories.save') : $t('admin.categories.create') }}</button>
          <button type="button" class="btn-secondary" @click="cancelForm">{{ $t('admin.categories.cancel') }}</button>
        </div>
      </form>
    </div>

    <div v-if="error" class="error-msg">{{ error }}</div>

    <div class="crud-table-wrap">
      <table v-if="items.length" class="crud-table">
        <thead>
          <tr>
            <th>{{ $t('admin.categories.id') }}</th>
            <th>{{ $t('admin.categories.name') }}</th>
            <th>{{ $t('admin.categories.actions') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in items" :key="item.id">
            <td>{{ item.id }}</td>
            <td>{{ item.nombre }}</td>
            <td class="actions">
              <button @click="openEdit(item)">{{ $t('admin.categories.edit') }}</button>
              <button class="btn-danger" @click="confirmDelete(item)">{{ $t('admin.categories.delete') }}</button>
            </td>
          </tr>
        </tbody>
      </table>
      <p v-else class="empty">{{ $t('admin.categories.empty') }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase.js'

const { t } = useI18n()

const TABLES = {
  pokeserie: 'categorias_pokeserie',
  pokefilm: 'categorias_pokefilm',
}

const tab = ref('pokeserie')
const items = ref([])
const showForm = ref(false)
const editing = ref(null)
const error = ref('')
const form = ref(emptyForm())

function emptyForm() {
  return { nombre: '' }
}

function currentTable() {
  return TABLES[tab.value]
}

async function load() {
  const { data, error: err } = await supabase.from(currentTable()).select('*').order('id')
  if (err) {
    error.value = err.message
  } else {
    items.value = data ?? []
  }
}

watch(tab, () => {
  showForm.value = false
  editing.value = null
  error.value = ''
  load()
})

function openCreate() {
  editing.value = null
  form.value = emptyForm()
  showForm.value = true
  error.value = ''
}

function openEdit(item) {
  editing.value = item
  form.value = { nombre: item.nombre }
  showForm.value = true
  error.value = ''
}

function cancelForm() {
  showForm.value = false
  editing.value = null
  error.value = ''
}

async function save() {
  error.value = ''
  const payload = { ...form.value }

  if (editing.value) {
    const { error: err } = await supabase.from(currentTable()).update(payload).eq('id', editing.value.id)
    if (err) { error.value = err.message; return }
  } else {
    const { error: err } = await supabase.from(currentTable()).insert(payload)
    if (err) { error.value = err.message; return }
  }

  showForm.value = false
  editing.value = null
  await load()
}

async function confirmDelete(item) {
  if (!confirm(t('admin.categories.confirmDelete', { name: item.nombre }))) return
  const { error: err } = await supabase.from(currentTable()).delete().eq('id', item.id)
  if (err) {
    error.value = err.message
  } else {
    await load()
  }
}

onMounted(load)
</script>

<style scoped>
</style>
