# nimview
A lightwight cross platform UI library for Nim, C, C++ or Python. The main purpose is to simplify creation of Desktop applications based on a HTML/CSS/JS layer that is displayed with Webview.

# About

The target of this project is to have a simple, ultra lightweight UI layer for Desktop and Cloud applications that have just a few MB in static executable size. The UI layer will be completely HTML/CSS/JS based and the backend should be using either Nim, C/C++ or Python code directly. Nim also acts as a "glue" layer as it makes it very easy to create python libs and can also create c libraries easily. The final result should be a binary executable that runs on Linux, Windows or (untested) MacOS  without the requirement to have some kind of webserver running. Running remote server applications might require an additional authentication and security reverse proy layer. Android is technically possible too but will need an additional project. 

The recommended frontend library is Vue with CSS Bootstrap to quickly build a reactive user interface. Svelte would have been an option too, as Svelte is easier to learn as Vue, but trying Svelte had some major issues running on Webview that couldn't be resolved easily.

Node.js will be required to build a Vue module. During development, the backend code will also create a simple HTTP server, so you can use all your usual debugging and development tools in Chrome or Firefox. Webview on its own is a mess if you want to debug your javascript issues.
This also means - the JS / HTML UI code will also be runnable in normal webbrowsers.

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
Nim is actually some great "batteries included" helper. It is similar readable as python, has some cool Json / HTTP Server / Webview modules but creates plain C Code that can be compiled by gcc compilers to optimized machine code. You can also include C/C++ code as the output of Nim is just plain C. Additionally, it can run python code or can be compiled to a python library by using "pynim" (https://robert-mcdermott.gitlab.io/posts/speeding-up-python-with-nim/).

### Which JS framework would be recommended.
I would recommend Bootstrap and Vue. There is an example for vue and bootstrap in tests/vue.
I already used to work with React and Redux. I really liked the advantage of using modules and using webpack, but I didn't like the verbosity of React or writing map-reducers for Redux. But if you want - you might just use the JS framework of your choice.
The main logic is in nimview.nim and backend-helper.js. Make sure to include backend-helper.js either in HTML include. There is a minimal sample in tests/minimal_sample.nim that doesn't need any additionl JS library. 
You just might be careful with modern frameworks that create javascript that webview doesn't understand. There have been some problems with Svelte as webview couldn't handle some javascript keywords.

### Why not Electron?
Electron is a great framework and it was also an inspiration to this helper here. However, using C++ Code is quite complicate in Electron and the output binary is usually more than 100 MB.
The Output of this tool here can be less than 2MB. Getting started might just take some minutes and it will consume less RAM, less system ressources and will start much quicker than an Electron App.

### Difference to Eel and Neel
There are some cool similar frameworks: The very popular framework "eel" (https://github.com/ChrisKnott/Eel) for python and its little brother neel (https://github.com/Niminem/Neel) for nim
There are 2 major differences: 
- Both eel and neel make it easy to call backend-server side functions from javascript and also call exposed javascript from backend. This is not any goal here with Nimview. Nimview will just make it easy to trigger backend routes from javascript but will not expose javascript functions to the backend side. If you want to do so, you need to parse the backends response and call the function with this data. This makes it possible to use multiple HTML / JS user interfaces for the same server code without worrying about javascript functions.
- With Nimview, you also don't need a webserver running that might take requests from any other user on localhost. This improves security and makes it possible to run multiple applications without having port conflicts.

## Project setup
```
- install nim (https://nim-lang.org/install.html or package manager)
    avoid whitespace in nim install folder name when using windows
    add path by running nim "finish" in the nim install directory, so you have nimble available
    restart or open new shell to have nimble available
- nimble install webview (version 0.1.1)
- nimble install jester, nimpy
- (linux) install gtk (yum install nim, gcc, npm, webkit2gtk3-devel) (apt install nim, gcc, npm, libwebkit2gtk-4.0-dev)
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

### Customize Vue configuration
See [Configuration Reference](https://cli.vuejs.org/config/).
