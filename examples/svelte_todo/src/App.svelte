<script>
	import backend from "nimview"
	import SortableList from './SortableList.svelte'
	
	let currentItem = ""
	let items = []
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
	const sortList = (ev) => {
		items = ev.detail
		storeAll()
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
					<SortableList items={items} key="id" on:sort={sortList} let:item let:index >
						<label class="ui-state-default">
							<input type="checkbox"  id="todo-{index}"
								on:click={() => {
									item.completed = !item.completed
									storeAll()
								}} 
								checked="{item.completed}" />
							<span>
									{item.text}
							</span>						
						</label>
						<a href={"#"} on:click|preventDefault={ () => deleteItem(item.id)} title="delete" class="delete float-right">x</a>
					</SortableList>
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
.delete {
  position: relative;
  top: 1px;
  font-size: 20px;
  color: #A00;
  margin-right: 9px;
}
</style>