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
import { ref } from 'vue'
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

function goToInfo() {
  router.push({ name: 'PokecuentoInfo', params: { id: props.pokecuento.id } })
}
</script>
