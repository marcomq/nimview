This package is part of [Nimview](https://github.com/marcomq/nimview/) and 
contains Javascript helpers to call server functions on nimview http server or 
nimview webview.

You should import it as 

`import backend from "nimview"`

The only function that might be called directly is 

`backend.waitInit().then(backend.someFunction)`