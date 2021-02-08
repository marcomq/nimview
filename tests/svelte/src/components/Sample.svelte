<script>
  let search = ""
  let elements = []
  let runSearch = function() {
    elements = elements.concat({text: search});
    window.ui.backend("appendSomething", search, function(response) { 
      search = response; 
    });
  };
</script>

<div class="container sample">
  <li class="form-inline">
    <form class="form-inline">
      <input class="form-control mr-sm-2" type="search" placeholder="Search for ..." aria-label="search" bind:value={search}>
      <button type="button" on:click={runSearch} class="btn btn-success my-2 my-sm-0">Search</button>
    </form>
  </li>
  <div>
    {#if ((typeof elements !== "undefined") && (elements.length > 0))}
      {#each elements as el}
      <div>
        {el.text}
      </div>
      {/each}
    {:else}
    <p>No data available yet</p>
    {/if}
  </div>
</div>

<style>
.sample {
  margin-top: 5px;
}
</style>