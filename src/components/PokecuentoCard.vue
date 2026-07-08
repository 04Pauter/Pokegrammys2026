<template>
  <div
    class="pokecuento-card"
    :class="{ selected }"
    :style="cardStyle"
    @click="$emit('select')"
    @mousemove="onMouseMove"
    @mouseleave="onMouseLeave"
    @mouseenter="onMouseEnter"
  >
    <div class="card-image" :class="{ loaded: imageLoaded }">
      <img :src="pokecuento.imagenurl" :alt="pokecuento.nombre" @load="imageLoaded = true" />
      <button class="info-btn" @click.stop="goToInfo" :title="$t('info.viewInfo')">&#8505;</button>
    </div>
    <div class="card-body">
      <h3 class="card-title">{{ pokecuento.nombre }}</h3>
      <p class="card-author">{{ pokecuento.autor }}</p>
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
  pokecuento: {
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
    transform: `perspective(800px) rotateX(${rotX}deg) rotateY(${rotY}deg) scale(1.03)`,
    transition: 'transform 0.1s ease'
  }
})

function sparkleStyle(i) {
  const angle = (i / 6) * 360
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
  router.push({ name: 'PokecuentoInfo', params: { id: props.pokecuento.id } })
}
</script>
