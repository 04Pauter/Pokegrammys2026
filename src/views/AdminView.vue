<template>
  <div class="admin-view">
    <h1>{{ $t('admin.title') }}</h1>
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

