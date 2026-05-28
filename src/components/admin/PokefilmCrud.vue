<template>
  <div class="crud-section">
    <div class="crud-header">
      <h2>{{ $t('admin.pokefilms.title') }}</h2>
      <button @click="openCreate">{{ $t('admin.pokefilms.new') }}</button>
    </div>

    <div v-if="showForm" class="crud-form">
      <h3>{{ editing ? $t('admin.pokefilms.editTitle') : $t('admin.pokefilms.newTitle') }}</h3>
      <form @submit.prevent="save">
        <input v-model="form.nombre" :placeholder="$t('admin.pokefilms.namePlaceholder')" required />
        <input v-model="form.autor" :placeholder="$t('admin.pokefilms.authorPlaceholder')" required />
        <input v-model="form.imagenurl" :placeholder="$t('admin.pokefilms.imagePlaceholder')" />
        <input v-model="form.audiourl" :placeholder="$t('admin.pokefilms.audioPlaceholder')" />
        <input v-model="form.videourl" :placeholder="$t('admin.pokefilms.videoPlaceholder')" />
        <div class="form-actions">
          <button type="submit">{{ editing ? $t('admin.pokefilms.save') : $t('admin.pokefilms.create') }}</button>
          <button type="button" class="btn-secondary" @click="cancelForm">{{ $t('admin.pokefilms.cancel') }}</button>
        </div>
      </form>
    </div>

    <div v-if="error" class="error-msg">{{ error }}</div>

    <table v-if="items.length" class="crud-table">
      <thead>
        <tr>
          <th>{{ $t('admin.pokefilms.id') }}</th>
          <th>{{ $t('admin.pokefilms.name') }}</th>
          <th>{{ $t('admin.pokefilms.author') }}</th>
          <th>{{ $t('admin.pokefilms.image') }}</th>
          <th>{{ $t('admin.pokefilms.actions') }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="item in items" :key="item.id">
          <td>{{ item.id }}</td>
          <td>{{ item.nombre }}</td>
          <td>{{ item.autor }}</td>
          <td>
            <img v-if="item.imagenurl" :src="item.imagenurl" :alt="item.nombre" class="thumb" />
          </td>
          <td class="actions">
            <button @click="openEdit(item)">{{ $t('admin.pokefilms.edit') }}</button>
            <button class="btn-danger" @click="confirmDelete(item)">{{ $t('admin.pokefilms.delete') }}</button>
          </td>
        </tr>
      </tbody>
    </table>
    <p v-else class="empty">{{ $t('admin.pokefilms.empty') }}</p>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase.js'

const { t } = useI18n()

const items = ref([])
const showForm = ref(false)
const editing = ref(null)
const error = ref('')
const form = ref(emptyForm())

const TABLE = 'pokefilm'

function emptyForm() {
  return { nombre: '', autor: '', imagenurl: '', audiourl: '', videourl: '' }
}

async function load() {
  const { data, error: err } = await supabase.from(TABLE).select('*').order('id')
  if (err) {
    error.value = err.message
  } else {
    items.value = data ?? []
  }
}

function openCreate() {
  editing.value = null
  form.value = emptyForm()
  showForm.value = true
  error.value = ''
}

function openEdit(item) {
  editing.value = item
  form.value = { ...item }
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
    const { error: err } = await supabase.from(TABLE).update(payload).eq('id', editing.value.id)
    if (err) { error.value = err.message; return }
  } else {
    const { error: err } = await supabase.from(TABLE).insert(payload)
    if (err) { error.value = err.message; return }
  }

  showForm.value = false
  editing.value = null
  await load()
}

async function confirmDelete(item) {
  if (!confirm(t('admin.pokefilms.confirmDelete', { name: item.nombre }))) return
  const { error: err } = await supabase.from(TABLE).delete().eq('id', item.id)
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
