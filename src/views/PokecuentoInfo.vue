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
                title="Vídeo de YouTube"
                frameborder="0"
                loading="lazy"
                referrerpolicy="strict-origin-when-cross-origin"
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
  // Si es deixa el lightbox obert i es navega fora, el body es
  // quedava amb `overflow: hidden` i l'app deixava de fer scroll.
  document.body.style.overflow = ''
})

watch(imageExpanded, (val) => {
  document.body.style.overflow = val ? 'hidden' : ''
})

function goBack() {
  router.push({ name: 'Pokecuento' })
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
  if (!pokecuento.value?.videourl) return false
  // Cal un ID vàlid, no només un domini de YouTube: si no, quedaria
  // un iframe buit en comptes del reproductor de vídeo normal.
  return getYoutubeVideoId(pokecuento.value.videourl) !== null
})

const youtubeEmbedUrl = computed(() => {
  if (!pokecuento.value?.videourl) return ''
  const videoId = getYoutubeVideoId(pokecuento.value.videourl)
  if (!videoId) return ''
  // youtube-nocookie redueix el seguiment de Google fins que es reprodueix.
  return `https://www.youtube-nocookie.com/embed/${videoId}`
})

async function loadPokecuento() {
  loading.value = true
  pokecuento.value = null
  try {
    const { data, error } = await supabase
      .from('pokecuento')
      .select('*')
      .eq('id', route.params.id)
      .maybeSingle()

    if (error) {
      console.error('Error fetching pokecuento:', error)
    } else if (data) {
      pokecuento.value = new Pokecuento(data)
    }
  } catch (err) {
    console.error('Error fetching pokecuento:', err)
  } finally {
    loading.value = false
  }
}

onMounted(loadPokecuento)

// El component es reutilitza per a /Pokecuento/:id/info: sense això
// es mostraven les dades de l'id anterior.
watch(() => route.params.id, loadPokecuento)
</script>
