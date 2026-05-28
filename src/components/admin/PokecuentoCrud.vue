<template>
  <div class="crud-section">
    <div class="crud-header">
      <h2>{{ $t('admin.pokecuentos.title') }}</h2>
      <button @click="openCreate">{{ $t('admin.pokecuentos.new') }}</button>
    </div>

    <div v-if="showForm" class="crud-form">
      <h3>{{ editing ? $t('admin.pokecuentos.editTitle') : $t('admin.pokecuentos.newTitle') }}</h3>
      <form @submit.prevent="save">
        <input v-model="form.nombre" :placeholder="$t('admin.pokecuentos.namePlaceholder')" required />
        <input v-model="form.autor" :placeholder="$t('admin.pokecuentos.authorPlaceholder')" required />
        <input v-model="form.imagenurl" :placeholder="$t('admin.pokecuentos.imagePlaceholder')" />
        <input v-model="form.audiourl" :placeholder="$t('admin.pokecuentos.audioPlaceholder')" />
        <input v-model="form.videourl" :placeholder="$t('admin.pokecuentos.videoPlaceholder')" />
        <div class="form-actions">
          <button type="submit">{{ editing ? $t('admin.pokecuentos.save') : $t('admin.pokecuentos.create') }}</button>
          <button type="button" class="btn-secondary" @click="cancelForm">{{ $t('admin.pokecuentos.cancel') }}</button>
        </div>
      </form>
    </div>

    <div v-if="error" class="error-msg">{{ error }}</div>

    <table v-if="items.length" class="crud-table">
      <thead>
        <tr>
          <th>{{ $t('admin.pokecuentos.id') }}</th>
          <th>{{ $t('admin.pokecuentos.name') }}</th>
          <th>{{ $t('admin.pokecuentos.author') }}</th>
          <th>{{ $t('admin.pokecuentos.image') }}</th>
          <th>{{ $t('admin.pokecuentos.actions') }}</th>
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
            <button @click="openEdit(item)">{{ $t('admin.pokecuentos.edit') }}</button>
            <button class="btn-danger" @click="confirmDelete(item)">{{ $t('admin.pokecuentos.delete') }}</button>
          </td>
        </tr>
      </tbody>
    </table>
    <p v-else class="empty">{{ $t('admin.pokecuentos.empty') }}</p>
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

const TABLE = 'pokecuento'

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
  if (!confirm(t('admin.pokecuentos.confirmDelete', { name: item.nombre }))) return
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
