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

      <div v-else-if="pokefilm" key="content" class="info-content">
        <!-- Lightbox backdrop -->
        <Teleport to="body">
          <Transition name="state-fade">
            <div v-if="imageExpanded" class="lightbox-backdrop" @click="imageExpanded = false" />
          </Transition>
        </Teleport>

        <!-- Hero image with lightbox effect -->
        <div class="info-image" :class="{ expanded: imageExpanded }" @click="imageExpanded = !imageExpanded">
          <img :src="pokefilm.imagenurl" :alt="pokefilm.nombre" />
          <div class="image-overlay">
            <span class="image-zoom-icon">{{ imageExpanded ? '✕' : '⤢' }}</span>
          </div>
        </div>

        <!-- Details glass card -->
        <div class="info-details">
          <div class="info-name-row">
            <h2 class="info-name">{{ pokefilm.nombre }}</h2>
            <span class="info-badge">★</span>
          </div>
          <p class="info-author">{{ $t('info.author') }}: <strong>{{ pokefilm.autor }}</strong></p>

          <div class="info-divider" />

          <div v-if="pokefilm.audiourl" class="info-media">
            <div class="media-label">
              <span class="media-icon">♫</span>
              <h3>{{ $t('info.audio') }}</h3>
            </div>
            <audio controls :src="pokefilm.audiourl" class="audio-player"></audio>
          </div>

          <div v-if="pokefilm.videourl" class="info-media">
            <div class="media-label">
              <span class="media-icon">▶</span>
              <h3>{{ $t('info.video') }}</h3>
            </div>
            <div class="video-wrapper">
              <iframe
                v-if="isYoutube"
                :src="youtubeEmbedUrl"
                title="Vídeo de YouTube"
                frameborder="0"
                loading="lazy"
                referrerpolicy="strict-origin-when-cross-origin"
                allowfullscreen>
              </iframe>
              <video v-else controls class="video-player">
                <source :src="pokefilm.videourl" />
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
import { Pokefilm } from '../models/Pokefilm.js'

const route = useRoute()
const router = useRouter()

const pokefilm = ref(null)
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
  // Si es deixa el lightbox obert i es navega fora, el body es
  // quedava amb `overflow: hidden` i l'app deixava de fer scroll.
  document.body.style.overflow = ''
})

watch(imageExpanded, (val) => {
  document.body.style.overflow = val ? 'hidden' : ''
})

function goBack() {
  router.push({ name: 'Pokefilm' })
}

// Només acceptem dominis oficials de YouTube. No fem servir includes():
// "youtube.com.exemple-maliciós.com" també hi passaria.
const YOUTUBE_HOSTS = new Set([
  'youtube.com',
  'www.youtube.com',
  'm.youtube.com',
  'youtu.be',
  'www.youtu.be'
])

function getYoutubeVideoId(urlString) {
  try {
    const url = new URL(urlString)
    const hostname = url.hostname.toLowerCase()
    let videoId = null

    if (hostname === 'youtu.be' || hostname === 'www.youtu.be') {
      videoId = url.pathname.slice(1).split('/')[0]
    } else if (YOUTUBE_HOSTS.has(hostname)) {
      const [, kind, id] = url.pathname.split('/')
      videoId = kind === 'shorts' || kind === 'embed' || kind === 'live'
        ? id
        : url.searchParams.get('v')
    }

    // Els IDs de YouTube fan exactament 11 caràcters.
    return videoId && /^[A-Za-z0-9_-]{11}$/.test(videoId) ? videoId : null
  } catch {
    return null
  }
}

const isYoutube = computed(() => {
  if (!pokefilm.value?.videourl) return false
  // Cal un ID vàlid, no només un domini de YouTube: si no, quedaria
  // un iframe buit en comptes del reproductor de vídeo normal.
  return getYoutubeVideoId(pokefilm.value.videourl) !== null
})

const youtubeEmbedUrl = computed(() => {
  if (!pokefilm.value?.videourl) return ''
  const videoId = getYoutubeVideoId(pokefilm.value.videourl)
  if (!videoId) return ''
  // youtube-nocookie redueix el seguiment de Google fins que es reprodueix.
  return `https://www.youtube-nocookie.com/embed/${videoId}`
})

async function loadPokefilm() {
  loading.value = true
  pokefilm.value = null
  try {
    const { data, error } = await supabase
      .from('pokefilm')
      .select('*')
      .eq('id', route.params.id)
      .maybeSingle()

    if (error) {
      console.error('Error fetching pokefilm:', error)
    } else if (data) {
      pokefilm.value = new Pokefilm(data)
    }
  } catch (err) {
    console.error('Error fetching pokefilm:', err)
  } finally {
    loading.value = false
  }
}

onMounted(loadPokefilm)

// El component es reutilitza per a /Pokefilm/:id/info: sense això
// es mostraven les dades de l'id anterior.
watch(() => route.params.id, loadPokefilm)
</script>
