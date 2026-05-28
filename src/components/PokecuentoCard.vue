<template>
  <div
    class="pokecuento-card"
    :class="{ selected }"
    @click="$emit('select')"
  >
    <div class="card-image">
      <img :src="pokecuento.imagenurl" :alt="pokecuento.nombre" />
    </div>
    <div class="card-body">
      <h3 class="card-title">{{ pokecuento.nombre }}</h3>
      <p class="card-author">{{ pokecuento.autor }}</p>
    </div>
  </div>
</template>

<script setup>
defineProps({
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
</script>

<style scoped>
</style>
