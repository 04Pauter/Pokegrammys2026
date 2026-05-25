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
.pokefilm-card {
  background: #16161e;
  border: 2px solid #2a2a35;
  border-radius: 12px;
  overflow: hidden;
  transition: transform 0.2s, border-color 0.2s, box-shadow 0.2s;
  cursor: pointer;
}

.pokefilm-card:hover {
  transform: translateY(-4px);
  border-color: #c9a84c;
  box-shadow: 0 8px 24px rgba(201, 168, 76, 0.15);
}

.pokefilm-card.selected {
  border-color: #c9a84c;
  box-shadow: 0 0 0 2px #c9a84c, 0 8px 24px rgba(201, 168, 76, 0.25);
}

.card-image {
  width: 100%;
  aspect-ratio: 16 / 9;
  overflow: hidden;
  background: #0e0e14;
}

.card-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.card-body {
  padding: 1rem 1.25rem;
}

.card-title {
  margin: 0;
  font-size: 1.1rem;
  font-weight: 700;
  color: #ffffff;
  line-height: 1.3;
}

.card-author {
  margin: 0.35rem 0 0;
  font-size: 0.85rem;
  color: #888;
}
</style>
