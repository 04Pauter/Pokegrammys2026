<template>
  <div
    ref="cardEl"
    class="voting-card"
    :class="{ selected }"
    role="radio"
    :aria-checked="selected"
    :tabindex="0"
    @click="$emit('select')"
    @keydown.enter.prevent="$emit('select')"
    @keydown.space.prevent="$emit('select')"
    @mousemove="onMouseMove"
    @mouseleave="onMouseLeave"
    @mouseenter="onMouseEnter"
  >
    <div class="card-border" />

    <!-- Position badge -->
    <div class="card-position-badge">
      <span>{{ position }}</span>
    </div>

    <div class="card-image" :class="{ loaded: imageLoaded, 'is-selected': selected }">
      <img
        :src="nominee.imagenurl"
        :alt="nominee.nombre"
        @load="imageLoaded = true"
        @error="imageLoaded = true"
      />
      <!-- Cursor-following sheen (position driven by --glow-x/--glow-y) -->
      <div class="card-glow" />
      <!-- Gradient overlay when selected -->
      <div class="card-image-overlay" />
      <!-- Info button (compact: no ha de robar el clic central de la targeta) -->
      <button
        class="info-btn"
        @click.stop="goToInfo"
        :title="$t('info.viewInfo')"
        :aria-label="$t('info.viewInfo')"
      >
        <span class="info-btn-icon">i</span>
      </button>
      <!-- Selected checkmark (bottom-right: no xoc amb el botó d'informació) -->
      <Transition name="check-pop">
        <div v-if="selected" class="selected-check">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
            <path d="M5 13l4 4L19 7" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </div>
      </Transition>
    </div>

    <div class="card-body">
      <h3 class="card-title">{{ nominee.nombre }}</h3>
      <p class="card-author">
        <span class="author-icon">♪</span>
        {{ nominee.autor }}
      </p>
    </div>

    <!-- Selected label -->
    <Transition name="label-slide">
      <div v-if="selected" class="selected-label">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
          <path d="M5 13l4 4L19 7" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
        <span>{{ $t('voting.selected') }}</span>
      </div>
    </Transition>

    <!-- Sparkles -->
    <div v-if="selected" class="card-sparkles">
      <div v-for="s in 10" :key="s" class="sparkle" :style="sparkleStyle(s)" />
    </div>

    <!-- Shimmer line when selected -->
    <div v-if="selected" class="card-shimmer-line" />
  </div>
</template>

<script setup>
import { ref, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'

const props = defineProps({
  nominee: { type: Object, required: true },
  selected: { type: Boolean, default: false },
  infoRouteName: { type: String, required: true },
  position: { type: Number, default: 1 }
})

defineEmits(['select'])

const router = useRouter()
const cardEl = ref(null)
const imageLoaded = ref(false)

/* --- Cursor-following sheen -----------------------------------
   Es calcula amb requestAnimationFrame i s'escriu directament
   com a variable CSS (--glow-x / --glow-y). Així no es
   reactivenitza el component a cada mousemove.                  */
let rafId = null
let pending = null

function flushGlow() {
  rafId = null
  const el = cardEl.value
  if (!el || !pending) return
  el.style.setProperty('--glow-x', pending.x.toFixed(1) + '%')
  el.style.setProperty('--glow-y', pending.y.toFixed(1) + '%')
}

function onMouseMove(e) {
  const el = cardEl.value
  if (!el) return
  const rect = el.getBoundingClientRect()
  if (!rect.width || !rect.height) return
  pending = {
    x: ((e.clientX - rect.left) / rect.width) * 100,
    y: ((e.clientY - rect.top) / rect.height) * 100
  }
  if (rafId === null) rafId = requestAnimationFrame(flushGlow)
}

function onMouseEnter() {
  cardEl.value?.style.setProperty('--glow-opacity', '1')
}

function onMouseLeave() {
  cardEl.value?.style.setProperty('--glow-opacity', '0')
}

onUnmounted(() => {
  if (rafId !== null) cancelAnimationFrame(rafId)
  rafId = null
})

function sparkleStyle(i) {
  const angle = (i / 10) * 360
  const dist = 25 + (i % 4) * 10
  const x = 50 + Math.cos((angle * Math.PI) / 180) * dist
  const y = 50 + Math.sin((angle * Math.PI) / 180) * dist
  const delay = i * 0.06
  const driftX = Math.cos((angle * Math.PI) / 180) * 30
  const driftY = Math.sin((angle * Math.PI) / 180) * 30 - 10
  return {
    left: x + '%',
    top: y + '%',
    animationDelay: delay + 's',
    '--drift-x': driftX + 'px',
    '--drift-y': driftY + 'px'
  }
}

function goToInfo() {
  router.push({ name: props.infoRouteName, params: { id: props.nominee.id } })
}
</script>
