<template>
  <div
    class="pokefilm-card"
    :class="{ selected }"
    @click="$emit('select')"
  >
    <div class="card-image">
      <img :src="pokefilm.imagenurl" :alt="pokefilm.nombre" />
      <button class="info-btn" @click.stop="goToInfo" :title="$t('info.viewInfo')">&#8505;</button>
    </div>
    <div class="card-body">
      <h3 class="card-title">{{ pokefilm.nombre }}</h3>
      <p class="card-author">{{ pokefilm.autor }}</p>
    </div>
  </div>
</template>

<script setup>
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

function goToInfo() {
  router.push({ name: 'PokefilmInfo', params: { id: props.pokefilm.id } })
}
</script>

<style scoped>
</style>
