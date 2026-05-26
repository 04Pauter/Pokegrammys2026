<template>
  <div class="admin-view">
    <h1>Panell d'Administració</h1>
    <!--<p>Benvingut, {{ auth.user?.email }}</p>-->

    <div class="admin-grid">
      <PokecuentoCrud />
      <PokefilmCrud />
      <CategoriaCrud />
      <NominatsCrud />
    </div>
  </div>
</template>

<script setup>
import { useAuthStore } from '@/stores/auth.js'
import PokecuentoCrud from '@/components/admin/PokecuentoCrud.vue'
import PokefilmCrud from '@/components/admin/PokefilmCrud.vue'
import CategoriaCrud from '@/components/admin/CategoriaCrud.vue'
import NominatsCrud from '@/components/admin/NominatsCrud.vue'

const auth = useAuthStore()
</script>

<style scoped>
.admin-view {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  gap: 1rem;
  padding: 2rem;
}

.admin-view h1 {
  font-size: 2.5rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: -0.02em;
}

.admin-grid {
  width: 100%;
  max-width: 960px;
  display: flex;
  flex-direction: column;
  gap: 2rem;
  margin-top: 1rem;
}
</style>
