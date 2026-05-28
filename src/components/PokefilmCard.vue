<template>
  <div
    class="pokefilm-card"
    :class="{ selected }"
    @click="$emit('select')"
  >
    <div class="card-image">
      <img :src="pokefilm.imagenurl" :alt="pokefilm.nombre" />
    </div>
    <div class="card-body">
      <h3 class="card-title">{{ pokefilm.nombre }}</h3>
      <p class="card-author">{{ pokefilm.autor }}</p>
    </div>
  </div>
</template>

<script setup>
defineProps({
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
</script>

<style scoped>
</style>
