<template>
  <div
    class="pokecuento-card"
    :class="{ selected }"
    @click="$emit('select')"
  >
    <div class="card-image">
      <img :src="pokecuento.imagenurl" :alt="pokecuento.nombre" />
      <button class="info-btn" @click.stop="goToInfo" :title="$t('info.viewInfo')">&#8505;</button>
    </div>
    <div class="card-body">
      <h3 class="card-title">{{ pokecuento.nombre }}</h3>
      <p class="card-author">{{ pokecuento.autor }}</p>
    </div>
  </div>
</template>

<script setup>
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

function goToInfo() {
  router.push({ name: 'PokecuentoInfo', params: { id: props.pokecuento.id } })
}
</script>

<style scoped>
</style>
