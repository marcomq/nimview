# nimvue
A Vue/Nim based helper to create Desktop/Server applications with Nim/C/C++ and HTML/CSS

# About

The target of this project is to have a UI Layer based on HTML/CSS with a backend based on Nim, C++ or Python. The UI layer will be completely JS / HTML / CSS based and the backend should be using either Nim, C++ or Python code directly with Nim as "glue". The final result should be a binary executable that runs on Linux, Windows or MacOS (Android is a bit complicated and will need an additional project) without the requirement to have some kind of webserver running. But if desired, you can just turn on the webserver to access the application from remote. Make sure to add some form of authentication in such a case, or anyone can run the application from remote.

The basic sample code will use Vue and bootstrap code to quickly build an reactive interface. I tried to use Svelte, as this is easier to learn as Vue, but Svelte had some issues running on Webview that I couldn't resolve easily.

Node.js will be required to build a Vue module and the Backend code will also create a simple HTTP server during development, so you can use all your usual debugging and development tools in Chrome, Firefox or Edge. Webview is a mess if you want to debug your javascript issues.
This means - the JS / HTML UI code will also be runnable in any browser.

This project is not intended to have any kind of additional helpers to create the UI. If you need some HTML generators or helpers, check the Vue (https://vuejs.org/) or the Vue-Bootstrap (https://bootstrap-vue.org/) library.



## Project setup
```
- install nim version 1.2 (https://nim-lang.org/install.html)
    avoid whitespace in nim install folder name when using windows
    add path by running nim "finish" in the nim install directory, so you have nimble available
    restart or open new shell to have nimble available
- nimble install webview (version 0.1.1)
- install node > 12.19  (https://nodejs.org/en/download/)
- run "cd ui", "npm install" and "cd .." 
- npm run build --prefix ui
- nim c -r --app:gui -d:release main.nim
```

### Why Nim?
Nim is actually some great "batteries included" helper. It is similar readable as python, has some cool Json / HTTP Server / Webview modules but creates plain C Code that can be compiled by any generic C compiler to optimized machine code. You can also include C/C++ code as the output of Nim is just plain C. Additionally, it can run python code or can be compiled to a python library by using "pynim" (https://robert-mcdermott.gitlab.io/posts/speeding-up-python-with-nim/).

### Why Vue?
I used to work with React and Redux during some previous job. I really liked the advantage of using modules and using webpack, but I didn't like the verbosity of React or writing map-reducers for Redux. Even if it solved some major problems of Javascript development, it felt like a major step back when comparing to the simplicity of jQuery. In fact, I just wanted to have some template engine with some little reactivity helpers. Svelte was really close, but I had issues made it running on Webview. Vue.js was the next candidate.
I'm still new to Vue, there are probably a lot of people out there who are much better in Vue.js.

### Can I use some other JS library
Sure. The main logic is in main.nim and ui/src/nimCall.js. Make sure to include nimCall.js either in your JS library or as HTML include. 

### Why not Electron?
Electron is a great Framework and it was also an inspiration to this helper here. However, using C++ Code is quite complicate as it requires WebAssemply and the output binary is usually more than 100 MB.
The Output of this tool here can be less than 2MB. Getting started might just take some minutes and it will consume less RAM and less system ressources than an Electron App.

### Compiles and hot-reloads for development
```
npm run serve --prefix ui
```

### Compiles and minifies for production
```
npm run build --prefix ui
```

### Lints and fixes files
```
npm run lint --prefix ui
```

### Customize configuration
See [Configuration Reference](https://cli.vuejs.org/config/).
