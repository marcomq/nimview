//App.vue
<template>
  <div id="app">
    <Navbar />
    <Main/>
  </div>
</template>
<script>
 import Navbar from './components/Navbar.vue'
 import Main from './components/Main.vue'
  export default {
    name: 'navbar',
    components: {
      Main,
      Navbar
    }
  }
  // still needs to change path in dist/index.html
</script>