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

<template>
<div class="container sample">
  <li class="form-inline">
    <form class="form-inline">
      <input class="form-control mr-sm-2" type="search" placeholder="Search for ..." aria-label="search"  v-model="search">
      <button type="button" v-on:click="runSearch" class="btn btn-success my-2 my-sm-0">Search</button>
    </form>
  </li>
  <div v-if="elements.length">
    <div v-for="item in elements" :key="item.val">
        <div>{{item.val}}</div>
    </div>
  </div>
  <div v-else>
    <p>No data available yet</p>
  </div>
</div>
</template>

<style scoped>
.sample {
  margin-top: 5px;
}
</style>