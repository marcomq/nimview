<script>
    import { createEventDispatcher } from "svelte"
    import { flip } from "svelte/animate"
  
    export let items
    export let key
    
    let hovering = false

    const dispatch = createEventDispatcher()
    const changeOrder = (from, to) => {
      let newList = [...items]
      newList[from] = [newList[to], (newList[to] = newList[from])][0]
      dispatch("sort", newList)
    }
    const dragStart = ev => {
      ev.dataTransfer.setData("source", ev.target.dataset.index)
    }
    const getDraggedDataset = (current) => {
      if (current.dataset.index) {
          return current.dataset
      }
      else {
          return getDraggedDataset(current.parentNode)
      }
    }
    const dragOver = (ev) => {
      ev.preventDefault()
      let dragged = getDraggedDataset(ev.target)
      if (hovering !== dragged.id) {
          hovering = JSON.parse(dragged.id)
      }
    }
    const dragLeave = (ev) => {
      let dragged = getDraggedDataset(ev.target)
      if (hovering === dragged.id) {
          hovering = false
      }
    }
    const drop = (ev) => {
      ev.preventDefault()
      hovering = false
      let dragged = getDraggedDataset(ev.target)
      let from = ev.dataTransfer.getData("source")
      let to = dragged.index
      changeOrder(from, to)
    }
  
    const getKey = (item) => {
        if (key) {
            return item[key]
        }
        else {
            return item
        }
    }
  </script>
  
  <style>
    ul {
      list-style: none;
      padding-left: 3px;
    }
    li {
      border: 2px dotted transparent;
    }
    .over {
      border-color: rgba(0, 0, 0, 0.3);
    }
  </style>
  
  {#if items && items.length}
    <ul>
      {#each items as item, index (getKey(item))}
        <li
          data-index={index}
          data-id={JSON.stringify(getKey(item))}
          draggable="true"
          on:dragstart={dragStart}
          on:dragover={dragOver}
          on:dragleave={dragLeave}
          on:drop={drop}
          animate:flip={{ duration: 150 }}
          class="ui-state-default"
          class:over={getKey(item) === hovering}>
          <slot {item} {index}>
            <p>{getKey(item)}</p>
          </slot>
        </li>
      {/each}
    </ul>
  {/if}
  