# Nimview 
![License](https://img.shields.io/github/license/marcomq/nimview) 
[![Build Status](https://github.com/marcomq/nimview/actions/workflows/linux.yml/badge.svg?branch=main)](https://github.com/marcomq/nimview/actions/workflows/linux.yml)
[![Build Status](https://github.com/marcomq/nimview/actions/workflows/windows.yml/badge.svg?branch=main)](https://github.com/marcomq/nimview/actions/workflows/windows.yml)
[![Build Status](https://github.com/marcomq/nimview/actions/workflows/macos.yml/badge.svg?branch=main)](https://github.com/marcomq/nimview/actions/workflows/macos.yml)


A lightweight cross platform UI library for Nim, C, C++ or Python. The main purpose is to simplify creation of online / offline applications based on a HTML/CSS/JS layer to be displayed with Webview or a browser. The application can run on cloud and on desktop with the same binary application.

## Table of Contents
- [About](#about)
- [Demo binary](#demo-binary)
- [Minimal Python Example](#minimal-python-example)
- [Minimal Nim example](#minimal-nim-example)
- [Javascript and HTML UI](#javascript-and-html-ui)
- [Exchange data with UI](#exchange-data-with-ui)
- [Development workflow](#development-workflow)
- [Why Nim](#why-nim)
- [Which JS framework for UI](#which-js-framework-for-ui)
- [Why not Electron or CEF](#why-not-electron-or-cef)
- [Difference to Eel](#difference-to-eel)
- [Difference to Flask](#difference-to-flask)
- [Multithreading](#multithreading)
- [Using UI from existing web-applications](#using-ui-from-existing-web-applications)
- [Setup from source](#setup-from-source)
- [Documentation](#documnentation)

## About

The target of this project was to have a simple, ultra lightweight cross platform, cross programming language UI layer for desktop, cloud and moblile applications. The application should have just a few MB in static executable size and should be easy to write, easy to read, stable and easy to test.
The UI layer will be completely HTML/CSS/JS based and the back-end should be using either Nim, C/C++ or Python code directly. 
Nim mostly acts as a "glue" layer as it can create python and C libraries easily. As long as you write Nim code, you might integrate the code in C/C++, Python or even Android. 
The final result should be a binary executable that runs on Linux, Windows or MacOS Desktop. A transform layer for all UI code and Nim functions to Android is here: https://github.com/marcomq/nimview_android
The application will only require to create a webserver in debug mode - or if there is no Desktop available.
Make sure to use an additional authentication and some security reverse proxy layer when running on cloud for production. 

Node.js is recommended if you want to build your Javascript UI layer with Svelte/Vue/React or the framework of your choice.
The HTTP server will run in debug mode by default, so you can use all your usual debugging and development tools in Chrome or Firefox. 
Webview on its own is a mess if you want to debug your Javascript issues. You might use it for production and testing, but you shouldn't focus Javascript UI development on Webview.

This project is not intended to have any kind of forms, inputs or any additional helpers to create the UI. 
If you need HTML generators or helpers, there are widely used open source frameworks available, for example Vue-Bootstrap (https://bootstrap-vue.org/).

## Demo binary
There is a pre-build demo windows x64 binary available that uses a simple Svelte UI. 
To make it work, you need to unzip everything before running the binaries. The zip contains two .exe files, 
one desktop application and one HTTP server application that can be reached at http://localhost:8000.
- [demo_app.zip](https://github.com/marcomq/nimview/files/6100203/demo_app.zip)

sha256sum 315035d4c26bf53e95e44d09def88c58c751d78c4436da4da8dde1139a88584c

To build this demo from source, you need to run `nimble demo`

## Minimal Python example
The project is available for python via `pip install nimview` and for nim via `nimble install nimview`. 
If you just want to display some simple static HTML (or alternatively a jpg in Python), you can run:

```
import nimview
nimview.start("hello_world.html")
```

If you want to actually trigger some server code from a button, you can do following:

```
import nimview
def echoAndModify(value):
    print ("From front-end: " + value)
    return (value + " appended")

nimview.addRequest("echoAndModify", echoAndModify)
nimview.start("minimal_ui_sample/index.html")
```

The same in nim:

## Minimal Nim example
```
import nimview
nimview.addRequest("echoAndModify", proc (value: string): string =
  echo "From front-end: " & value
  result = "'" & value & "' modified by back-end")
nimview.start("minimal_ui_sample/index.html")
```

These examples will take the "minimal_ui_sample/index.html" file relative to the binary / python file.
It's parent folder "minimal_ui_sample" will act as root "/" for all URLs.

## Javascript and HTML UI
(simlified, using a button, only the important part)
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
- the first one is the request function that is registered on back-end.
- the second one is the value that is sent to the back-end
- the third value is a callback function.
 
An alternative signature, optimized for Vue.js is following:
`window.ui.backend(request, object, key)`
In this case, `object[key]` will be sent to back-end and there is an automated callback that will update `object[key]` with the back-end response. 
This is not expected to work with Svelte, as the modification of the object would be hidden for Svelte and doesn't add the reactivity you might expect.

You need to include your own error handler in the callback, as there is no separate error callback function. 
There probably will not be any separate error callback to keep it simple.


## Exchange data with UI
Does this mean I can only send just one single value and just receive just one single value from back-end?
Yes and No - it is recommended to use Json to encode your values on the client, use a parser on the back-end to read all values and send Json back to the client. 
This is amazingly easy when using python or Nim as back-end. By this, all requests can be stored as simple strings and easily be used for automated tests.
In case you want to use C++ - don't write your own C++ Json parser. Feel free to use https://github.com/nlohmann/json. You might re-use it in other code locations.

## Development workflow
You need to compile the back-end and usually the front-end too, when using vue or svelte. While this seems unnecessary complicated in the beginning, 
you will have the freedom to only restart the back-end if you have back-end changes and 
use some autoreload feature of webpack (vue) and rollit (svelte) for the frontend.
The setup/install after installing nim would be: 
- `nimble install nimview`
- `npm install --prefix <path_to_ui_folder>`
The development workflow would be:
- start your back-end in debug mode with vs code or terminal, run: `nimble debug && ./nimview_debug`
- start your frontend npm in autoreload with vs code or terminal, run `npm run dev --prefix <path_to_ui_folder>`
- open a browser with url http://localhost:5000 to see the current front-end code result that is served by node.js
- change your front-end code, the page will reload automatically
- change your back-end code and use the debug restart button in vs code when finished
- keep in mind that http://localhost:5000 is only a development url, the Javascript generated for production would be reachable by default at http://localhost:8000

### Why Nim
Nim is actually some great "batteries included" helper. It is similar readable as python, has some cool Json / HTTP Server / Webview modules 
but creates plain C Code that can be compiled by gcc compilers to optimized machine code. 
You can also include C/C++ code as the output of Nim is just plain C. Additionally, it can be compiled to a python library easily. 
(https://robert-mcdermott.gitlab.io/posts/speeding-up-python-with-nim/).

### Which JS framework for UI
There are many JS frameworks to choose to create a responsive UI.
Svelte will create the fastest and most readable front-end code. But it is completely up to you which framework you will choose. 
There is an example for Vue + Bootstrap in tests/vue and one for Svelte in tests/svelte.
I already used to work with React and Redux. I really liked the advantage of using modules and using webpack, 
but I didn't like the verbosity of React or writing map-reducers for Redux, so I didn't add an example for React yet.
The main logic is in nimview.nim and backend-helper.js. Make sure to include backend-helper.js either in the static HTML includes. 
There is a minimal sample in tests/minimal_sample.nim that doesn't need any additionl JS library. 

### Why not Electron or CEF
Electron and CEF are great frameworks and both were an inspiration to this helper here. 
However, the output binary of electron or CEF is usually more than 100 MB and getting started with a new project can also take some time. 
Both CEF and Electron might be great for large Desktop projects that don't need to care about RAM + Disk or that need some additional custom window color,
task symbols or other features. But setting those up and deploying them takes a lot of time, which you can safe by using this helper here.
The output of this tool here can be less than 2MB. It also might just run in the Cloud as there is an included webserver 
- you might easily run the app in Docker. Getting started might just take some minutes and it will consume less RAM, 
less system resources and will start much quicker than an Electron or CEF App.
Also, you will have all the included features of nim if you decide to build a C++ Code. 
You might write the same Code and the same UI for your Cloud application as for your Desktop App.

### Difference to Eel and Neel
There are some cool similar frameworks: The very popular framework "eel" (https://github.com/ChrisKnott/Eel) for python 
and its little brother neel (https://github.com/Niminem/Neel) for nim
There are 2 major differences: 
- Both eel and neel make it easy to call back-end side functions from Javascript and also call exposed Javascript from back-end. 
This is not any goal here with Nimview. 
  Nimview will just make it easy to trigger back-end routes from Javascript but will not expose Javascript functions to the back-end side. 
  If you want to do so, you need to parse the back-end’s response and call the function with this data. 
  This makes it possible to use multiple HTML / JS user interfaces for the same back-end code without worrying about javascript functions.
- With Nimview, you also don't need a webserver running that might take requests from any other user on localhost. 
This improves security and makes it possible to run multiple applications without having port conflicts.

### Difference to Flask
Flask is probably the most popular python framework to create micro services (https://github.com/pallets/flask) and Nimview/Jester probably cannot compete with the completeness of Flask for simple python cloud applications. Nimview for example will not support server side template engines as flask does.
But Nimview is written in Nim and creates static binaries that can run in a minimal tiny Docker container that doesn't need an installed python environment. So you might create containers for your application that have just a few MB. So those deploy and startup much faster than Flask applications. Make sure to avoid building with Webview when creating binaries for Docker, or you need to include GTK libraries in your container.

### Multithreading
Nim has a thread local heap and most variables in Nimview are declared thread local. It is therefore not possible to share Nimview data between multiple threads automatically. Check the Nim manual on how to deal with multithreading and sharing data, for example with Channels.

### Using UI from existing web-applications and how to handle paths
For Desktop applications, it is required to use relative file paths in all your HTML. The paths must point to a directory relative of the binary to the given index html file.
It is not possible to use a subdirectory of the index file. You can also not use a web URL as startpoint, as this must be an existing file.
It is also not recommended to load anything via an URL from any existing internet source, as this could easily cause a security breach.
The Desktop mode is using IE11 as platform, so there might be security issues when loading uncontrolled content from internet.

## Setup from source 
If you don't want to use `nimble install` and build everything from scratch
```
- install nim (https://nim-lang.org/install.html or package manager)
    avoid white-space in nim install folder name when using windows
    add path by running nim "finish" in the nim install directory, so you have nimble available
    restart or open new shell to have nimble available
- (linux:  yum install gcc, npm, webkitgtk4-devel <or:> apt install gcc npm libwebkit2gtk-4.0-dev)
- (windows: install node > 12.19  (https://nodejs.org/en/download/)
- git clone https://github.com/marcomq/nimview
- cd nimview
- nimble install -d -y
- run "cd tests/vue", "npm install" and "cd ../.." 
- run "cd tests/svelte", "npm install" and "cd ../.." 
- nimble debug && ./nimview.exe
- (other console) npm run dev --prefix <ui folder of your choice>
```

### Documentation
A documentation is [here](https://htmlpreview.github.io/?https://github.com/marcomq/nimview/blob/master/docs/nimview.html)
