<template>
  <div class="pokecuento-card">
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
  }
})
</script>

<style scoped>
.pokecuento-card {
  background: #16161e;
  border: 1px solid #2a2a35;
  border-radius: 12px;
  overflow: hidden;
  transition: transform 0.2s, border-color 0.2s, box-shadow 0.2s;
  cursor: pointer;
}

.pokecuento-card:hover {
  transform: translateY(-4px);
  border-color: #c9a84c;
  box-shadow: 0 8px 24px rgba(201, 168, 76, 0.15);
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
