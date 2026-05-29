<template>
  <div class="info-view">
    <header class="info-header">
      <button class="back-btn" @click="goBack">&larr; {{ $t('info.back') }}</button>
      <h1>{{ $t('info.title') }}</h1>
    </header>

    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>{{ $t('voting.loading') }}</p>
    </div>

    <div v-else-if="pokecuento" class="info-content">
      <div class="info-image">
        <img :src="pokecuento.imagenurl" :alt="pokecuento.nombre" />
      </div>

      <div class="info-details">
        <h2 class="info-name">{{ pokecuento.nombre }}</h2>
        <p class="info-author">{{ $t('info.author') }}: {{ pokecuento.autor }}</p>

        <div v-if="pokecuento.audiourl" class="info-media">
          <h3>{{ $t('info.audio') }}</h3>
          <audio controls :src="pokecuento.audiourl" class="audio-player"></audio>
        </div>

        <div v-if="pokecuento.videourl" class="info-media">
          <h3>{{ $t('info.video') }}</h3>
          <iframe
            v-if="isYoutube"
            width="560"
            height="315"
            :src="youtubeEmbedUrl"
            frameborder="0"
            allowfullscreen>
          </iframe>
          <video v-else controls width="560" class="video-player">
            <source :src="pokecuento.videourl" />
          </video>
        </div>
      </div>
    </div>

    <div v-else class="loading-state">
      <p>{{ $t('info.notFound') }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../lib/supabase.js'
import { Pokecuento } from '../models/Pokecuento.js'

const route = useRoute()
const router = useRouter()

const pokecuento = ref(null)
const loading = ref(true)

function goBack() {
  router.push({ name: 'Pokecuento' })
}

import { computed } from 'vue'

function isYoutubeUrl(urlString) {
  try {
    const url = new URL(urlString)
    const hostname = url.hostname.toLowerCase()
    return hostname.includes('youtube.com') || hostname === 'youtu.be'
  } catch {
    return false
  }
}

function getYoutubeVideoId(urlString) {
  try {
    const url = new URL(urlString)
    if (url.hostname === 'youtu.be') {
      return url.pathname.slice(1).split('/')[0]
    }
    return url.searchParams.get('v')
  } catch {
    return null
  }
}

const isYoutube = computed(() => {
  if (!pokecuento.value?.videourl) return false
  return isYoutubeUrl(pokecuento.value.videourl)
})

const youtubeEmbedUrl = computed(() => {
  if (!pokecuento.value?.videourl) return ''
  const videoId = getYoutubeVideoId(pokecuento.value.videourl)
  if (!videoId) return ''
  return `https://www.youtube.com/embed/${videoId}`
})

onMounted(async () => {
  const { data, error } = await supabase
    .from('pokecuento')
    .select('*')
    .eq('id', route.params.id)
    .single()

  if (error) {
    console.error('Error fetching pokecuento:', error)
  } else {
    pokecuento.value = new Pokecuento(data)
  }

  loading.value = false
})
</script>

<style>
</style>
