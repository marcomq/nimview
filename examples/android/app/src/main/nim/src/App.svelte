<script>
	import backend from "nimview"
	
	let currentItem = ""
	let items = []
	let mainInput
	let addItem = () => {
		items.push({id: Math.max(0, ...items.map(t => t.id)) + 1, text: currentItem, completed: false})
		items = items
		currentItem = ""
		storeAll()
		mainInput.focus()
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
		try {
			let jsonResponse = await backend.getStoredVal("items")
			items = JSON.parse(jsonResponse)
		} 
		catch (e) {
			console.log(e)
		}
		mainInput.focus()
	}
	let countDown = () => {
        backend.countDown().then(response => {
            alert(0)
        })
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
                <button type="button" on:click={countDown} class="btn btn-success my-2 my-sm-0">Countdown</button>
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
									checked="{item.completed}" />{item.text}
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
</style>