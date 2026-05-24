<template>
  <div class="login-view">
    <h1>Login</h1>
    <router-link to="/Home">Home</router-link>
  </div>
</template>

<style scoped>
.login-view {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  flex: 1;
  text-align: center;
  gap: 1rem;
  padding: 2rem;
}

.login-view h1 {
  font-size: 2.5rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: -0.02em;
}
</style>