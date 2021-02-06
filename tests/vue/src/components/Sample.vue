//src/components/Sample.vue
// https://blog.logrocket.com/getting-started-with-bootstrapvue-2d8bf907ef11/
<template>
<div>
  <b-container>
  <b-nav-form>
    <b-form-input 
      size="sm" 
      class="mr-sm-2" 
      placeholder="Search for..."
      v-model="search"
      ></b-form-input>
    <b-button 
      size="sm" 
      class="my-2 my-sm-0" 
      type="submit" 
      @click.prevent="runSearch"
      >Search</b-button>
  </b-nav-form>
    <div v-if="elements.length">
      <div v-for="item in elements" :key="item.val">
          <div>{{item.val}}</div>
      </div>
    </div>
    <div v-else>
      <h5>No data available yet ??</h5>
    </div>
  </b-container>
</div>
</template>

<script>
export default {
  data() {
    return {
      elements: [],
      search: ''
    };
  },
  methods: {
    runSearch() {
      this.backend("appendSomething", this, 'search'); // calling the backend
      this.elements.push({val: this.search})
    }
  }
};
</script>