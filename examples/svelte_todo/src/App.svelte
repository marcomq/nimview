<script>
	import backend from "nimview"
	
	let currentItem = ""
	let items = []
	let hovering = false
	let mainInput

	const addItem = () => {
		items.push({id: Math.max(0, ...items.map(t => t.id)) + 1, text: currentItem, completed: false})
		items = items
		currentItem = ""
		storeAll()
		mainInput.focus()
	}
	const deleteItem = (id) => {
		items = items.filter(item => item.id !== id)
		storeAll()
	}
	const uncheckAll = () => {
		items.map(item => item.completed = false)
		items = items
		storeAll()
	}
	const checkAll = () => {
		items.map(item => item.completed = true)
		items = items
		storeAll()
	}
	const storeAll = () => {
		backend.setStoredVal("items", JSON.stringify(items))
	}
	const getAll = async () => {
		try {
			let jsonResponse = await backend.getStoredVal("items")
			items = JSON.parse(jsonResponse)
		} 
		catch (e) {
			console.log(e)
		}
		mainInput.focus()
	}
	$: backend.waitInit().then(() => {getAll()})

	const drop = (event, target) => {
		event.dataTransfer.dropEffect = 'move'; 
		const start = parseInt(event.dataTransfer.getData("text/plain"));
		const newTracklist = items

		if (start < target) {
			newTracklist.splice(target + 1, 0, newTracklist[start]);
			newTracklist.splice(start, 1);
		} else {
			newTracklist.splice(target, 0, newTracklist[start]);
			newTracklist.splice(start + 1, 1);
		}
		items = newTracklist
		storeAll()
		hovering = null
	}
	const dragstart = (event, i) => {
		event.dataTransfer.effectAllowed = 'move';
		event.dataTransfer.dropEffect = 'move';
		const start = i;
		event.dataTransfer.setData('text/plain', start);
	}
</script>
<main>
	<nav class="navbar navbar-expand-lg navbar-dark bg-success ">
	<div class="container">
		<a class="navbar-brand" on:click|preventDefault href={"#"} >Todo App</a>
	</div>
	</nav>
	<div class="container">
		<div class="row">
			<div class="col">
				<form on:submit|preventDefault={addItem}>
					<div class="input-group mainInput">
						<input type="text" class="form-control add-todo" bind:this={mainInput} bind:value="{currentItem}" placeholder="Add todo" />
						<div class="input-group-append">
							<button class="btn btn-outline-success" type="submit">Add</button>
						</div>
					</div>
				</form>
				{#if items.length > 0}
				<ul id="sortable" class="list-unstyled">
				{#each items as item}
					<li class="ui-state-default">
						<label>
							<input type="checkbox"  id="todo-{item.id}"
								on:click={() => {
									item.completed = !item.completed
									storeAll()
								}} 
								checked="{item.completed}" />
							<span 
								draggable={true} 
								on:dragstart={event => dragstart(event, item.id)}
								on:drop|preventDefault={event => drop(event, item.id)}
								on:dragenter={() => hovering = item.id}
								class:is-active={hovering === item.id}
								ondragover="return false">
									{item.text}
							</span>						
						</label>
						<a href={"#"} on:click|preventDefault={ () => deleteItem(item.id)} title="delete" class="delete float-right">x</a>

					</li>
				{/each}
				</ul>
				<div class="footer">
					<div class="float-left">
						<strong><span class="count-todos">{items.length}</span></strong>
						{#if items.length == 1}
						Item
						{:else}
						Items
						{/if}
					</div>
					<div class="float-right">
						<button id="uncheckAll" on:click={uncheckAll} class="btn btn-outline-success">Un-check all</button>
						<button id="checkAll" on:click={checkAll} class="btn btn-outline-success">All done</button>
					</div>
				</div>
				{/if}
			</div>
		</div>
	</div>
</main>
<style>
.row .col {
	max-width: 600px;
}
.mainInput {
	margin-top: 20px;
	margin-bottom: 20px;
}
.footer {
	padding-bottom: 45px;
}
ul li input, .count-todos{
    margin-right: 9px;
    margin-left: 3px;
}
.delete {
  position: relative;
  top: 1px;
  font-size: 20px;
  color: #A00;
  margin-right: 9px;
}
.is-active {
    background-color: #3273dc;
    color: #fff;
}
</style>