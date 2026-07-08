<template>
  <div
    class="voting-card"
    :class="{ selected }"
    :style="cardStyle"
    @click="$emit('select')"
    @mousemove="onMouseMove"
    @mouseleave="onMouseLeave"
    @mouseenter="onMouseEnter"
  >
    <div class="card-glow" :style="glowStyle" />
    <div class="card-border" />

    <!-- Position badge -->
    <div class="card-position-badge">
      <span>{{ position }}</span>
    </div>

    <div class="card-image" :class="{ loaded: imageLoaded, 'is-selected': selected }">
      <img
        :src="nominee.imagenurl"
        :alt="nominee.nombre"
        :style="imageStyle"
        @load="imageLoaded = true"
      />
      <!-- Gradient overlay when selected -->
      <div class="card-image-overlay" />
      <!-- Info button with label -->
      <button class="info-btn" @click.stop="goToInfo" :title="$t('info.viewInfo')">
        <span class="info-btn-icon">i</span>
        <span class="info-btn-label">{{ $t('info.viewInfo') || 'Info' }}</span>
      </button>
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

    <!-- Selected checkmark (top-right) -->
    <Transition name="check-pop">
      <div v-if="selected" class="selected-check">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
          <path d="M5 13l4 4L19 7" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
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
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'

const props = defineProps({
  nominee: { type: Object, required: true },
  selected: { type: Boolean, default: false },
  infoRouteName: { type: String, required: true },
  position: { type: Number, default: 1 }
})

defineEmits(['select'])

const router = useRouter()
const imageLoaded = ref(false)
const isHovered = ref(false)
const mouseX = ref(0)
const mouseY = ref(0)
const cardRect = ref(null)

function onMouseEnter(e) {
  isHovered.value = true
  cardRect.value = e.currentTarget.getBoundingClientRect()
}

function onMouseLeave() {
  isHovered.value = false
  mouseX.value = 0
  mouseY.value = 0
}

function onMouseMove(e) {
  if (!cardRect.value) return
  const rect = cardRect.value
  const x = (e.clientX - rect.left) / rect.width
  const y = (e.clientY - rect.top) / rect.height
  mouseX.value = (x - 0.5) * 2
  mouseY.value = (y - 0.5) * 2
}

const cardStyle = computed(() => {
  if (!isHovered.value) return {}
  const rotX = mouseY.value * -8
  const rotY = mouseX.value * 8
  return {
    transform: `perspective(800px) rotateX(${rotX}deg) rotateY(${rotY}deg) scale(1.03)`,
    transition: 'transform 0.1s ease'
  }
})

const glowStyle = computed(() => {
  if (!isHovered.value) return { opacity: 0 }
  const x = (mouseX.value + 1) * 50
  const y = (mouseY.value + 1) * 50
  return {
    opacity: 0.7,
    background: `radial-gradient(circle at ${x}% ${y}%, rgba(212, 168, 67, 0.5), transparent 50%)`
  }
})

const imageStyle = computed(() => {
  if (!isHovered.value) return {}
  const moveX = mouseX.value * -6
  const moveY = mouseY.value * -6
  return {
    transform: `translate(${moveX}px, ${moveY}px) scale(1.08)`
  }
})

function sparkleStyle(i) {
  const angle = (i / 10) * 360
  const dist = 25 + (i % 4) * 10
  const x = 50 + Math.cos(angle * Math.PI / 180) * dist
  const y = 50 + Math.sin(angle * Math.PI / 180) * dist
  const delay = i * 0.06
  const driftX = Math.cos(angle * Math.PI / 180) * 30
  const driftY = Math.sin(angle * Math.PI / 180) * 30 - 10
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
