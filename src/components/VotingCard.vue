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

    <div class="card-image" :class="{ loaded: imageLoaded }">
      <img
        :src="nominee.imagenurl"
        :alt="nominee.nombre"
        :style="imageStyle"
        @load="imageLoaded = true"
      />
      <button class="info-btn" @click.stop="goToInfo" :title="$t('info.viewInfo')">&#8505;</button>
    </div>
    <div class="card-body">
      <h3 class="card-title">{{ nominee.nombre }}</h3>
      <p class="card-author">{{ nominee.autor }}</p>
    </div>

    <Transition name="check-pop">
      <div v-if="selected" class="selected-check">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
          <path d="M5 13l4 4L19 7" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </div>
    </Transition>

    <div v-if="selected" class="card-sparkles">
      <div v-for="s in 8" :key="s" class="sparkle" :style="sparkleStyle(s)" />
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'

const props = defineProps({
  nominee: { type: Object, required: true },
  selected: { type: Boolean, default: false },
  infoRouteName: { type: String, required: true }
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
  const rotX = mouseY.value * -10
  const rotY = mouseX.value * 10
  return {
    transform: `perspective(800px) rotateX(${rotX}deg) rotateY(${rotY}deg) scale(1.04)`,
    transition: 'transform 0.1s ease'
  }
})

const glowStyle = computed(() => {
  if (!isHovered.value) return { opacity: 0 }
  const x = (mouseX.value + 1) * 50
  const y = (mouseY.value + 1) * 50
  return {
    opacity: 0.6,
    background: `radial-gradient(circle at ${x}% ${y}%, rgba(212, 168, 67, 0.45), transparent 55%)`
  }
})

const imageStyle = computed(() => {
  if (!isHovered.value) return {}
  const moveX = mouseX.value * -8
  const moveY = mouseY.value * -8
  return {
    transform: `translate(${moveX}px, ${moveY}px) scale(1.1)`
  }
})

function sparkleStyle(i) {
  const angle = (i / 8) * 360
  const dist = 30 + (i % 3) * 12
  const x = 50 + Math.cos(angle * Math.PI / 180) * dist
  const y = 50 + Math.sin(angle * Math.PI / 180) * dist
  const delay = i * 0.07
  return {
    left: x + '%',
    top: y + '%',
    animationDelay: delay + 's'
  }
}

function goToInfo() {
  router.push({ name: props.infoRouteName, params: { id: props.nominee.id } })
}
</script>
