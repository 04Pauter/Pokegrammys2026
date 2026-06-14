<template>
  <div class="info-view">
    <!-- Background orbs -->
    <div class="info-orb info-orb-1" />
    <div class="info-orb info-orb-2" />

    <header class="info-header">
      <button class="back-btn" @click="goBack">← {{ $t('info.back') }}</button>
      <h1>{{ $t('info.title') }}</h1>
    </header>

    <Transition name="state-fade" mode="out-in">
      <div v-if="loading" key="loading" class="loading-state">
        <div class="spinner"></div>
        <p>{{ $t('voting.loading') }}</p>
      </div>

      <div v-else-if="pokecuento" key="content" class="info-content">
        <!-- Lightbox backdrop -->
        <Teleport to="body">
          <Transition name="state-fade">
            <div v-if="imageExpanded" class="lightbox-backdrop" @click="imageExpanded = false" />
          </Transition>
        </Teleport>

        <!-- Hero image with lightbox effect -->
        <div class="info-image" :class="{ expanded: imageExpanded }" @click="imageExpanded = !imageExpanded">
          <img :src="pokecuento.imagenurl" :alt="pokecuento.nombre" />
          <div class="image-overlay">
            <span class="image-zoom-icon">{{ imageExpanded ? '✕' : '⤢' }}</span>
          </div>
        </div>

        <!-- Details glass card -->
        <div class="info-details">
          <div class="info-name-row">
            <h2 class="info-name">{{ pokecuento.nombre }}</h2>
            <span class="info-badge">★</span>
          </div>
          <p class="info-author">{{ $t('info.author') }}: <strong>{{ pokecuento.autor }}</strong></p>

          <div class="info-divider" />

          <div v-if="pokecuento.audiourl" class="info-media">
            <div class="media-label">
              <span class="media-icon">♫</span>
              <h3>{{ $t('info.audio') }}</h3>
            </div>
            <audio controls :src="pokecuento.audiourl" class="audio-player"></audio>
          </div>

          <div v-if="pokecuento.videourl" class="info-media">
            <div class="media-label">
              <span class="media-icon">▶</span>
              <h3>{{ $t('info.video') }}</h3>
            </div>
            <div class="video-wrapper">
              <iframe
                v-if="isYoutube"
                :src="youtubeEmbedUrl"
                frameborder="0"
                allowfullscreen>
              </iframe>
              <video v-else controls class="video-player">
                <source :src="pokecuento.videourl" />
              </video>
            </div>
          </div>
        </div>
      </div>

      <div v-else key="not-found" class="loading-state">
        <p>{{ $t('info.notFound') }}</p>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../lib/supabase.js'
import { Pokecuento } from '../models/Pokecuento.js'

const route = useRoute()
const router = useRouter()

const pokecuento = ref(null)
const loading = ref(true)
const imageExpanded = ref(false)

function onEscape(e) {
  if (e.key === 'Escape' && imageExpanded.value) {
    imageExpanded.value = false
  }
}

onMounted(() => {
  document.addEventListener('keydown', onEscape)
})

onUnmounted(() => {
  document.removeEventListener('keydown', onEscape)
})

watch(imageExpanded, (val) => {
  document.body.style.overflow = val ? 'hidden' : ''
})

function goBack() {
  router.push({ name: 'Pokecuento' })
}

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
