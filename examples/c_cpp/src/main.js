import App from './App.svelte'
import 'jquery/dist/jquery.js'
import 'bootstrap/dist/js/bootstrap.bundle.js'
import 'bootstrap/dist/css/bootstrap.css'

var app
document.addEventListener("DOMContentLoaded", function() { 
    app = new App({
        target: document.body,	
    })
})

export default app