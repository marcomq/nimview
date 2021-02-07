<script>
  let search
  let elements = []
  let runSearch = function() {
    window.ui.backend("appendSomething", search, function(response) { search = response; });
      elements = elements.concat({text: search});
    };
    elements.push({val: search})
</script>

<div class="container">
  <li class="form-inline">
    <form class="form-inline">
      <input class="form-control mr-sm-2" type="search" placeholder="Search for ..." aria-label="search" bind:value={search}>
      <button  on:click={runSearch} class="btn btn-outline-success my-2 my-sm-0">Search</button>
    </form>
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
  </li>
</div>