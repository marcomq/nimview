//src/components/Sample.vue
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
      <b-row>
        <div v-bind:key="data.index" v-for="data in elements">
          <b-col l="4">
            <b-card
              v-bind:title="data.strCategory"
              v-bind:img-src="data.strCategoryThumb"
              img-alt="Image"
              img-top
              tag="article"
              style="max-width: 20rem;"
              class="mb-2">
              <b-card-text>{{ `${data.strCategoryDescription.slice(0,100)}...` }}</b-card-text>
              <b-button href="#" variant="primary">View data</b-button>
            </b-card>
          </b-col>
        </div>
      </b-row>
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
    }
  }
};
</script>