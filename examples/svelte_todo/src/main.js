import App from './App.svelte';

var app
document.addEventListener("DOMContentLoaded", function() { 
    app = new App({
        target: document.body,	
    })
})

export default app