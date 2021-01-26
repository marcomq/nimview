# nimview
A lightweight cross platform UI library for Nim, C, C++ or Python. The main purpose is to simplify creation of Desktop applications based on a HTML/CSS/JS layer that is displayed with Webview.

# About

The target of this project is to have a simple, ultra lightweight cross platform, cross language UI layer for Desktop and Cloud applications that have just a few MB in static executable size. 
The UI layer will be completely HTML/CSS/JS based and the back-end should be using either Nim, C/C++ or Python code directly. 
Nim also acts as a "glue" layer as it makes it very easy to create python libs and can also create c libraries easily. 
The final result should be a binary executable that runs on Linux, Windows or (untested) MacOS  without the requirement to have some kind of web-server running. 
Running remote server applications might require an additional authentication and security reverse proy layer. Android is technically possible too but will need an additional project. 

The recommended front-end library is Vue with CSS Bootstrap to quickly build a reactive user interface. 
Svelte would have been an option too, as Svelte is easier to learn as Vue, but trying Svelte had some major issues running on Webview that couldn't be resolved easily.

Node.js will be required to build a Vue module. 
During development, the back-end code will also create a simple HTTP server, so you can use all your usual debugging and development tools in Chrome or Firefox. 
Webview on its own is a mess if you want to debug your javascript issues.
This also means - the JS / HTML UI code will also be runnable in normal web-browsers.

This project is not intended to have any kind of forms, inputs or any additional helpers to create the UI. 
If you need HTML generators or helpers, check the Vue (https://vuejs.org/) or the Vue-Bootstrap (https://bootstrap-vue.org/) library.

## minimal nim sample
```
import nimview
nimview.addRequest("echoAndModify", proc (value: string): string =
  echo "From front-end: " & value
  result = "'" & value & "' modified by back-end")
nimview.start("minimal_ui_sample/index.html")
```
## minimal python sample
```
import nimporter, nimview
def echoAndModify(value):
    print ("From front-end: " + value)
    return (value + " appended")

nimview.addRequest("echoAndModify", echoAndModify)
nimview.start("minimal_ui_sample/index.html")
```

These examples will take the "minimal_ui_sample/index.html" file relative to the binary / python file.
It's parent folder "minimal_ui_sample" will act as root "/" for all URLs.

## on the js client side (only the important part)
```
<script src="backend-helper.js"></script>
<script type="text/javascript">
    function sampleFunction() {
        window.ui.backend('echoAndModify', document.getElementById('sampleInput').value, function(response) { 
			alert(response); 
		});
    }
</script>
<input id="sampleInput" type="text" value="Hello World" />
<button onclick=sampleFunction>click</button>
```

`window.ui.backend(request, value, callback)` can take up to 3 parameters:
- the first one is the request function that is registered on server side.
- the second one is the value that is sent to the back-end
- the third value is a callback function
 
An alternative signature, optimized for Vue.js is following:
`window.ui.backend(request, object, key)`
In this case, `object[key]` will be sent to back-end and there is an automated callback that will update `object[key]` with the server response

## Does this mean I can only send just 1 value and just receive just 1 value from server?
Yes and No - you can use Json to encode your values on the client, use a parser on the back-end to read all values and send Json back to the client. This is amazingly easy when using python or Nim as back-end. 
And there are also a lot of easy and fast Json Parsers / Encoders for C++. Don't write your own C++ Json parser, feel free to google and use the one of your choice. You will probably re-use it in other code locations

### Why Nim?
Nim is actually some great "batteries included" helper. It is similar readable as python, has some cool Json / HTTP Server / Webview modules but creates plain C Code that can be compiled by gcc compilers to optimized machine code. 
You can also include C/C++ code as the output of Nim is just plain C. Additionally, it can be compiled to a python library easily. (https://robert-mcdermott.gitlab.io/posts/speeding-up-python-with-nim/).

### Which JS framework would be recommended.
I would recommend Bootstrap and Vue. There is an example for Vue and Bootstrap in tests/vue.
I already used to work with React and Redux. I really liked the advantage of using modules and using webpack, but I didn't like the verbosity of React or writing map-reducers for Redux. But if you want - you might just use the JS framework of your choice.
The main logic is in nimview.nim and backend-helper.js. Make sure to include backend-helper.js either in HTML include. There is a minimal sample in tests/minimal_sample.nim that doesn't need any additionl JS library. 
You just might be careful with modern frameworks that create javascript that Webview doesn't understand. There have been some problems with Svelte as Webview couldn't handle some Javascript keywords.

### Why not Electron or CEF?
Electron is a great framework and it was also an inspiration to this helper here. However, using C++ Code is quite complicate in Electron. In CEF, it is easy to use C++, but the output binary is usually more than 100 MB and getting started with a new project can take some time. 
So, it might be good for large projects but a bit of overkill for small lighweight applications that just want some small UI.
The output of this tool here can be less than 2MB. Getting started might just take some minutes and it will consume less RAM, less system resources and will start much quicker than an Electron or CEF App.
Keep also in mind, that you might use the same source code for offline-desktop and cloud UIs when using Nimview.

### Difference to Eel and Neel
There are some cool similar frameworks: The very popular python framework "eel" (https://github.com/ChrisKnott/Eel) and its little brother neel (https://github.com/Niminem/Neel) for nim
There are 2 major differences: 
- Both eel and neel make it easy to call back-end-server side functions from Javascript and also call exposed Javascript from back-end. This is not any goal here with Nimview. 
  Nimview will just make it easy to trigger back-end routes from Javascript but will not expose Javascript functions to the back-end side. 
  If you want to do so, you need to parse the back-end’s response and call the function with this data. This makes it possible to use multiple HTML / JS user interfaces for the same server code without worrying about javascript functions.
- With Nimview, you can also disable having a webserver running that might take requests from any other user on localhost. This improves security and makes it possible to run multiple applications without bothering about port conflicts.

## Project setup
```
- install nim (https://nim-lang.org/install.html or package manager)
    avoid white-space in nim install folder name when using windows
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