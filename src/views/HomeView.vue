<template>
  <div class="home-view">
    <h1>Pokegrammys 2026</h1>
    <router-link to="/Pokecuento" class="cta-link">Votacion</router-link>
  </div>
</template>

<style scoped>
.home-view {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  flex: 1;
  text-align: center;
  gap: 1.5rem;
  padding: 2rem;
}

.home-view h1 {
  font-size: 3rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: -0.02em;
}

.cta-link {
  display: inline-block;
  padding: 0.75rem 2rem;
  background: #c9a84c;
  color: #0a0a0f;
  font-weight: 700;
  border-radius: 8px;
  font-size: 1rem;
  transition: background 0.2s;
}

.cta-link:hover {
  background: #e0c66a;
  color: #0a0a0f;
}
</style>