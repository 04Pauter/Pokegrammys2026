<template>
  <div class="crud-section">
    <div class="crud-header">
      <h2>Categories</h2>
      <div class="tab-bar">
        <button :class="{ active: tab === 'pokeserie' }" @click="tab = 'pokeserie'">Pokeserie</button>
        <button :class="{ active: tab === 'pokefilm' }" @click="tab = 'pokefilm'">Pokefilm</button>
      </div>
      <button @click="openCreate">Nova Categoria</button>
    </div>

    <div v-if="showForm" class="crud-form">
      <h3>{{ editing ? 'Editar Categoria' : 'Nova Categoria' }}</h3>
      <form @submit.prevent="save">
        <input v-model="form.nombre" placeholder="Nom de la categoria" required />
        <div class="form-actions">
          <button type="submit">{{ editing ? 'Guardar' : 'Crear' }}</button>
          <button type="button" class="btn-secondary" @click="cancelForm">Cancel·lar</button>
        </div>
      </form>
    </div>

    <div v-if="error" class="error-msg">{{ error }}</div>

    <table v-if="items.length" class="crud-table">
      <thead>
        <tr>
          <th>ID</th>
          <th>Nom</th>
          <th>Accions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="item in items" :key="item.id">
          <td>{{ item.id }}</td>
          <td>{{ item.nombre }}</td>
          <td class="actions">
            <button @click="openEdit(item)">Editar</button>
            <button class="btn-danger" @click="confirmDelete(item)">Eliminar</button>
          </td>
        </tr>
      </tbody>
    </table>
    <p v-else class="empty">No hi ha categories.</p>
  </div>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'
import { supabase } from '@/lib/supabase.js'

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
  if (!confirm(`Segur que vols eliminar "${item.nombre}"?`)) return
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
.crud-section {
  background: #111118;
  border: 1px solid #2a2a35;
  border-radius: 12px;
  padding: 1.5rem;
}

.crud-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  flex-wrap: wrap;
  gap: 0.75rem;
}

.crud-header h2 {
  margin: 0;
  font-size: 1.5rem;
}

.tab-bar {
  display: flex;
  gap: 0.25rem;
  background: #0e0e14;
  border-radius: 8px;
  padding: 0.25rem;
}

.tab-bar button {
  padding: 0.4rem 1rem;
  font-size: 0.85rem;
  background: transparent;
  color: #888;
  border-radius: 6px;
}

.tab-bar button.active {
  background: #2a2a35;
  color: #fff;
}

.tab-bar button:hover:not(.active) {
  color: #ccc;
}

.crud-form {
  background: #0e0e14;
  border: 1px solid #2a2a35;
  border-radius: 8px;
  padding: 1.25rem;
  margin-bottom: 1rem;
}

.crud-form h3 {
  margin: 0 0 1rem;
  font-size: 1.15rem;
}

.crud-form form {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
}

.form-actions {
  display: flex;
  gap: 0.75rem;
}

.btn-secondary {
  background: #2a2a35;
  color: #ccc;
}

.btn-secondary:hover {
  background: #3a3a45;
}

.btn-danger {
  background: #c0392b;
}

.btn-danger:hover {
  background: #e74c3c;
}

.crud-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.crud-table th,
.crud-table td {
  padding: 0.65rem 0.75rem;
  border-bottom: 1px solid #2a2a35;
  text-align: left;
}

.crud-table th {
  font-weight: 700;
  color: #c9a84c;
  font-size: 0.85rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.crud-table td.actions {
  white-space: nowrap;
  display: flex;
  gap: 0.5rem;
}

.crud-table td.actions button {
  padding: 0.4rem 0.9rem;
  font-size: 0.8rem;
}

.empty {
  color: #666;
  font-style: italic;
}

.error-msg {
  color: #e74c3c;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}
</style>
