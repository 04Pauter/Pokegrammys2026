<template>
  <div class="admin-view">
    <!-- Background ambient -->
    <div class="admin-orb admin-orb-1" />
    <div class="admin-orb admin-orb-2" />

    <h1>{{ $t('admin.title') }}</h1>

    <div class="admin-grid">
      <PokecuentoCrud />
      <PokefilmCrud />
      <CategoriaCrud />
      <NominatsCrud />
    </div>
  </div>
</template>

<script setup>
import PokecuentoCrud from '@/components/admin/PokecuentoCrud.vue'
import PokefilmCrud from '@/components/admin/PokefilmCrud.vue'
import CategoriaCrud from '@/components/admin/CategoriaCrud.vue'
import NominatsCrud from '@/components/admin/NominatsCrud.vue'
</script>

