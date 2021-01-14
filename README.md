# nimview
A lightwight cross platform UI library for Nim, C, C++ or Python. The main purpose is to simplify creation of Desktop applications based on a HTML/CSS/JS layer that is displayed with Webview.

# About

The target of this project is to have a simple, lightweight UI layer for Desktop applications that have just a few MB in static executable size. The UI layer will be completely HTML/CSS/JS based and the backend should be using either Nim, C/C++ or Python code directly with Nim as "glue". The final result should be a binary executable that runs on Linux, Windows or (untested) MacOS  without the requirement to have some kind of webserver running. Running remote server applications might are possible and too, but require an additional authentication layer. Android will need an additional project. 

The recommended frontend library would be Vue and Bootstrap code to quickly build an reactive interface. I tried to use Svelte, as this is easier to learn as Vue, but Svelte had some issues running on Webview that I couldn't resolve easily.

Node.js will be required to build a Vue module and the backend code will also create a simple HTTP server during development, so you can use all your usual debugging and development tools in Chrome or Firefox. Webview on its own is a mess if you want to debug your javascript issues.
This also means - the JS / HTML UI code will also be runnable in any browser.

This project is not intended to have any kind of additional helpers to create the UI. If you need some HTML generators or helpers, check the Vue (https://vuejs.org/) or the Vue-Bootstrap (https://bootstrap-vue.org/) library.

## minimal nim sample
```
import nimview
nimview.addRequest("echoAndModify", proc (value: string): string =
  echo "From Frontend: " & value
  result = "'" & value & "' modified by Backend")
nimview.start("minimal_ui_sample/index.html")
```
## minimal python sample
```
import nimporter, nimview
def echoAndModify(value):
    print ("From Frontend: " + value)
    return (value + " appended")

nimview.addRequest("echoAndModify", echoAndModify)
nimview.start("minimal_ui_sample/index.html")
```

### Why Nim?
Nim is actually some great "batteries included" helper. It is similar readable as python, has some cool Json / HTTP Server / Webview modules but creates plain C Code that can be compiled by any generic C compiler to optimized machine code. You can also include C/C++ code as the output of Nim is just plain C. Additionally, it can run python code or can be compiled to a python library by using "pynim" (https://robert-mcdermott.gitlab.io/posts/speeding-up-python-with-nim/).

### Why is Vue recommended?
I used to work with React and Redux during some previous job. I really liked the advantage of using modules and using webpack, but I didn't like the verbosity of React or writing map-reducers for Redux. Even if it solved some major problems of Javascript development, it felt like a major step back when comparing to the simplicity of jQuery. In fact, I just wanted to have some template engine with some little reactivity helpers. Svelte was really close, but I had issues made it running on Webview. Vue.js was the next candidate.
I'm still new to Vue, there are probably a lot of people out there who are much better in Vue.js.

### Can I use some other JS library
Sure. The main logic is in nimview.nim and backend-helper.js. Make sure to include backend-helper.js either in HTML include. There is a minimal sample in tests/minimal_sample.nim that doesn't need any additionl JS library.

### Why not Electron?
Electron is a great Framework and it was also an inspiration to this helper here. However, using C++ Code is quite complicate as it requires WebAssemply and the output binary is usually more than 100 MB.
The Output of this tool here can be less than 2MB. Getting started might just take some minutes and it will consume less RAM and less system ressources than an Electron App.

### Difference to Eel and Neel
There are some similar frameworks - eel (https://github.com/ChrisKnott/Eel)  for python and neel (https://github.com/Niminem/Neel) for nim
There are 2 major differences here: 
- Both neel and eel trigger javascript code in the nim/python backend as response. So the server has a major impact on the frontend feedback as it decides, how the frondend will continue. With nimview, the backend only receives json and sends back json. The frontend will handle this json and will decide which callback will be run. You may use multiple frontends for the same backend without worrying about any callback on the server side.
- With Nimview, you don't need a webserver running that might take requests from any other user on localhost. This improves security and makes it possible to run multiple applications without having port conflicts

## Project setup
```
- install nim version 1.2 (https://nim-lang.org/install.html)
    avoid whitespace in nim install folder name when using windows
    add path by running nim "finish" in the nim install directory, so you have nimble available
    restart or open new shell to have nimble available
- nimble install webview (version 0.1.1)
- nimble install jester, nimpy
- (linux) install gtk (yum install gcc, npm, webkit2gtk3-devel) (apt install gcc, npm, libwebkit2gtk-4.0-dev)
- install node > 12.19  (https://nodejs.org/en/download/)
- run "cd tests/vue", "npm install" and "cd .." 
- npm run build --prefix tests/vue
- nim c -r --app:gui -d:release nimview.nim 
# alternatively for debugging, will start jester instead of webview
- nim c -r --threads:on --debuginfo  --debugger:native --verbosity:2 -d:debug nimview.nim
```

### Compiles and hot-reloads for development
```
npm run serve --prefix tests/vue
```

### Compiles and minifies for production
```
npm run build --prefix tests/vue
```

### Lints and fixes files
```
npm run lint --prefix tests/vue
```

### Customize configuration
See [Configuration Reference](https://cli.vuejs.org/config/).
