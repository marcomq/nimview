<script>
	export let name;
	let elements = []
	let clickHandler = function () {
		window.ui.backend("appendSomething", name, function(response) { name = response; });
		elements = elements.concat({text: name});
	};
</script>
<!-- 
<script>
	import Navbar from './components/Navbar.svelte'
 	import Sample from './components/Sample.svelte'
</script>
<main>
	<div id="app">
	  <Navbar />
	  <Sample/>
	</div>
  </main>
-->
<main>
	<div>
		<input bind:value={name}>
		<h1>Hello {name}!</h1>
		<p>Visit the <a href="https://svelte.dev/tutorial">Svelte tutorial</a> to learn how to build Svelte apps.</p>
		<p></p>
		<button type="button" on:click={clickHandler}>
			Send input to Backend
		</button>
		<div>
			{#each elements as el}
			<div>
				{el.text}
			</div>
			{/each}
		</div>
	</div>
</main>

<style>
	main {
		text-align: center;
		padding: 1.1em;
		max-width: 250px;
		margin: 0 auto;
	}

	h1 {
		color: #ff3e00;
		text-transform: uppercase;
		font-size: 3.5em;
		font-weight: 100;
	}

	@media (min-width: 630px) {
		main {
			max-width: none;
		}
	}
</style>