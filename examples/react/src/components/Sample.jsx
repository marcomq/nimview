import backend from "nimview"
import React from "react"

class Sample extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      search: '',
      elements: []
    }
  }
  renderItems = () => {
    const elementItems = this.state.elements.map((item) =>
      <div>{item.val}</div>
    )
    return elementItems
  }

  countDown = () => { 
    backend.countDown().then(() => {
      alert(0)
    })
  }

  runSearch = () => {
    const newElements = this.state.elements
    newElements.push({val: this.state.search})
    backend.appendSomething(this.state.search).then((resp) => {
      this.setState({search: resp, elements: newElements})
    }) // calling the backend
  }

  updateSearch = (event) => {
    this.setState({search: event.target.value})
  }

  render() {
    return <div class="container sample" style={{marginTop: "5px"}}>
      <li class="form-inline">
        <form class="form-inline">
          <input class="form-control mr-sm-2" type="search" placeholder="Search for ..." aria-label="search" onChange={this.updateSearch} value={this.state.search} />
          <button type="button" style={{marginRight: '10px',}} onClick={this.runSearch} class="btn btn-success my-2 my-sm-0">Search</button>
          <button type="button" style={{marginRight: '10px',}} onClick={this.countDown} class="btn btn-success my-2 my-sm-0">Count down</button>
        </form>
      </li>
      <div>{this.renderItems()}</div>
    </div>
  }
}
export default Sample
