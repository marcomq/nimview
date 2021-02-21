//App.vue
<template>
  <div id="app">
    <Navbar />
    <Sample/>
  </div>
</template>
<script>
 import Navbar from './components/Navbar.vue'
 import Sample from './components/Sample.vue'
  export default {
    components: {
      Sample,
      Navbar
    }
  }
  // still needs to change path in dist/index.html
</script>