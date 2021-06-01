<script>
	import backend from "nimview"
	// import { onMount } from "svelte"
	let currentItem = ""
	let items = []
	let addItem = () => {
		items.push({id: Math.max(0, ...items.map(t => t.id)) + 1, text: currentItem, completed: false})
		items = items
		currentItem = ""
		storeAll()
	}
	let deleteItem = (id) => {
		items = items.filter(item => item.id !== id)
		storeAll()
	}
	let uncheckAll = () => {
		items.map(item => item.completed = false)
		items = items
		storeAll()
	}
	let checkAll = () => {
		items.map(item => item.completed = true)
		items = items
		storeAll()
	}
	let storeAll = () => {
		backend.setStoredVal("items", JSON.stringify(items))
	}
	let getAll = async () => {
		let jsonResponse = await backend.getStoredVal("items")
		try {
			jsonResponse = JSON.parse(jsonResponse)
			items = jsonResponse
		} 
		catch (e) {
			console.log(e)
		}
	}
	// onMount(async () => {
	//  	backend.waitInit().then(() => {getAll()})
	// })
	$: backend.waitInit().then(() => {getAll()})
</script>
<main>
	<div id="app">
		<nav class="navbar navbar-expand-lg navbar-dark bg-success ">
		<div class="container">
			<a class="navbar-brand" on:click|preventDefault href={"#"} >Todo</a>
		</div>
		</nav>
		<div class="container">
			<div class="row">
				<div class="col-sm-6">
					<div class="todolist not-done">
						<br/> 
						<form on:submit|preventDefault={addItem}>
							<div class="input-group">
								<input type="text" class="form-control add-todo" bind:value="{currentItem}" placeholder="Add todo" />
								<div class="input-group-append">
									<button class="btn btn-outline-success" type="submit">Add</button>
								</div>
							</div>
						</form>
					</div>
					
					<br/>
					{#if items.length > 0}
					<ul id="sortable" class="list-unstyled">
					{#each items as item}
						<li class="ui-state-default">
							<div class="checkbox">
								<label>
									<input type="checkbox"  id="todo-{item.id}"
										on:click={() => {
											item.completed = !item.completed
											storeAll()
										}} 
										checked="{item.completed}" />{item.text}
								</label>
								<a href={"#"} on:click|preventDefault={ () => deleteItem(item.id)} title="delete" class="delete float-right">x</a>
							</div>
						</li>
					{/each}
						
					</ul>
					<div class="todo-footer">
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
						<div class="col">
						</div>
					</div>
					{/if}
				</div>
			</div>
		</div>
	</div>
</main>
<style>

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
</style>