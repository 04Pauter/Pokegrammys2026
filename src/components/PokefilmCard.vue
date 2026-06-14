<template>
  <div
    class="pokefilm-card"
    :class="{ selected }"
    :style="cardStyle"
    @click="$emit('select')"
    @mousemove="onMouseMove"
    @mouseleave="onMouseLeave"
    @mouseenter="onMouseEnter"
  >
    <!-- Glow follow cursor -->
    <div class="card-glow" :style="glowStyle" />

    <!-- Shimmer border -->
    <div class="card-border" />

    <div class="card-image" :class="{ loaded: imageLoaded }">
      <img
        :src="pokefilm.imagenurl"
        :alt="pokefilm.nombre"
        :style="imageStyle"
        @load="imageLoaded = true"
      />
      <button class="info-btn" @click.stop="goToInfo" :title="$t('info.viewInfo')">&#8505;</button>
    </div>
    <div class="card-body">
      <h3 class="card-title">{{ pokefilm.nombre }}</h3>
      <p class="card-author">{{ pokefilm.autor }}</p>
    </div>

    <!-- Selection sparkles -->
    <div v-if="selected" class="card-sparkles">
      <div v-for="s in 6" :key="s" class="sparkle" :style="sparkleStyle(s)" />
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'

const props = defineProps({
  pokefilm: {
    type: Object,
    required: true
  },
  selected: {
    type: Boolean,
    default: false
  }
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
    transform: `perspective(800px) rotateX(${rotX}deg) rotateY(${rotY}deg) scale(1.02)`,
    transition: 'transform 0.1s ease'
  }
})

const glowStyle = computed(() => {
  if (!isHovered.value) return { opacity: 0 }
  const x = (mouseX.value + 1) * 50
  const y = (mouseY.value + 1) * 50
  return {
    opacity: 0.5,
    background: `radial-gradient(circle at ${x}% ${y}%, rgba(212, 168, 67, 0.4), transparent 60%)`
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
  const angle = (i / 6) * 360
  const dist = 35 + (i % 2) * 15
  const x = 50 + Math.cos(angle * Math.PI / 180) * dist
  const y = 50 + Math.sin(angle * Math.PI / 180) * dist
  const delay = i * 0.1
  return {
    left: x + '%',
    top: y + '%',
    animationDelay: delay + 's'
  }
}

function goToInfo() {
  router.push({ name: 'PokefilmInfo', params: { id: props.pokefilm.id } })
}
</script>
