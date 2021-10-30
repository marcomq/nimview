# Nimview 
![License](https://img.shields.io/github/license/marcomq/nimview) 
[![Build Status](https://github.com/marcomq/nimview/actions/workflows/linux.yml/badge.svg?branch=main)](https://github.com/marcomq/nimview/actions/workflows/linux.yml)
[![Build Status](https://github.com/marcomq/nimview/actions/workflows/windows.yml/badge.svg?branch=main)](https://github.com/marcomq/nimview/actions/workflows/windows.yml)
[![Build Status](https://github.com/marcomq/nimview/actions/workflows/macos.yml/badge.svg?branch=main)](https://github.com/marcomq/nimview/actions/workflows/macos.yml)


A lightweight cross platform UI library for Nim, C, C++ or Python. The main purpose is to simplify creation of online / offline applications based on a HTML/CSS/JS layer to be displayed with Webview or a browser. The application can even run on cloud and on desktop environments with the same binary application.

## Features
- Compile to small single executable binary that also includes the UI
- No network port will be opened by Nimview in Desktop mode
- Platforms: Windows, Linux, MacOS, Android, Cloud / Web
- Use Nim, Python, C or C++ for your back-end
- Use any HTML/CSS/JS based UI you want - Svelte, Vue, React, plain JS etc..
- Desktop and Web mode
- Simple automated back-end testing as backend functions just return strings
- Integrated simple persistent storage
- Immediately expose back-end functions to front-end with a simple command
- Trigger front-end functions from backend 

## Table of Contents
- [About](#about)
- [Demo binary](#demo-binary)
- [Minimal Python Example](#minimal-python-example)
- [Minimal Nim example](#minimal-nim-example)
- [Javascript and HTML UI](#javascript-and-html-ui)
- [Exchange data with UI](#exchange-data-with-ui)
- [Development workflow](#development-workflow)
- [Inline HTML to single binary](#inline-html-to-single-binary)
- [Why Nim](#why-nim)
- [Which JS framework for UI](#which-js-framework-for-ui)
- [Nimview vs Electron or CEF](#nimview-vs-electron-or-cef)
- [Nimview vs Eel or Neel](#nimview-vs-eel-or-neel)
- [Difference to Flask](#difference-to-flask)
- [Wails](#wails)
- [CSRF and Security](#csrf-and-security)
- [Multithreading](#multithreading)
- [IE 11 or - "Why is my page blank?](#multithreading)
- [Limitations](#limitations)
- [Using UI from existing web-applications](#using-ui-from-existing-web-applications)
- [Software Requirements](#software-requirements)
- [Documentation](#documnentation)


## About

The target of this project was to have a simple, ultra lightweight cross platform, cross programming language UI layer for desktop, cloud and moblile applications. Nimview applications have just a few MB in static executable size and are targeted to be easy to write, easy to read, stable and easy to test. The RAM consumption of basic Nimview applications is usually less than 20 MB.

This project uses [Webview](https://github.com/oskca/webview) to render Desktop 
applications and an integrated HttpServer for Development and Cloud.

Nimview is an interface to interact with Nim/C/C++/Python code from UI Javascript in the same way for Webview desktop applications, web and mobile applications. It registers functions in the specific languages and also can mix Nim with any of the supported targets. 

Technically, the UI layer will be completely HTML/CSS/JS based and the back-end should be using either Nim, C/C++ or Python code directly. 
Nim mostly acts as a "glue" layer as it can create python and C libraries easily. As long as you write Nim code, you might integrate the code in C/C++, Python or even Android. 
The final result should be a binary executable that runs on Linux, Windows or MacOS Desktop and even [Android](https://github.com/marcomq/examples/android). IOS wasn't tested yet.

The final application later doesn't require a webserver, but it is recommended to use the webserver during development or in debug mode.
You may also use the webserver for your cloud environemnt, but make sure to use additional authentication and a security reverse proxy when running on cloud.

Node.js is recommended but not required if you want to build your Javascript UI layer with Svelte/Vue/React or the framework of your choice.
The HTTP server will run when compiling the application as "debug" by default, so you can use all your usual debugging and development tools in Chrome or Firefox. 
Webview makes it hard to debug Javascript - especially on Windows. You might use webview for production and testing, but you shouldn't focus Javascript UI development on Webview on windows.

This project is not intended to have any kind of forms, inputs or any additional helpers to create the UI. 
If you need HTML generators or helpers, there are widely used open source frameworks available, for example Vue-Bootstrap (https://bootstrap-vue.org/).

## Demo binary
There is a pre-build "Todo-list" demo application for windows x64 that uses a simple Svelte UI. 
To make it work, you need to unzip everything before running the binaries. The zip contains two .exe files, 
one desktop application "appTodo" and one HTTP server application "httpTodo" that opens a server on
http://localhost:8000.
- [demo.zip](https://github.com/marcomq/nimview/files/7077224/demo.zip)
sha256sum df3d2595b9755b27b7034ce4970f44d3bca72544ce8915739062b4ba1d977158

If you want to build this demo from source, you need to run `nimble demo` on the
Nimview base folder.

## Minimal Python example
The project is available for python via `pip install nimview` and for nim via `nimble install nimview`. 
If you just want to display some simple static HTML (or alternatively a jpg), you can run:

```
import nimview
nimview.start("hello_world.html")
```

If you want to actually trigger some server code from a button, you can do following in Python:

```
import nimview
def echoAndModify(value): # One input value in the function signature is required
    print ("From front-end: " + value)
    return (value + " appended")

nimview.addRequest("echoAndModify", echoAndModify)
nimview.start("minimal_ui_sample/index.html")
```

The same in Nim:

## Minimal Nim example
```
import nimview
nimview.addRequest("echoAndModify", proc (value: string): string =
  echo "From front-end: " & value
  result = "'" & value & "' modified by back-end")
nimview.start()
```

Nimview will automatically use "../public/index.html" as as entry page in debug mode
and will try to load "../dist/inlined.html" in release mode. In release mode, the 
inlined.html entry point
will be compiled statically into the release binary. If there are no further dependencies,
the release binary can just run as single executable binary without further UI files.
Keep in mind that when running in webserver mode, it will expose all files and subfolders that in the same directory as the index.html.

## Javascript and HTML UI
Nimview offers an npm package "npm install nimview" which makes your life easier 
on the front-end.
If you want to trigger back-end code from Javascript, you can do following
async callback:
```
import backend from "nimview"
backend.waitInit().then(() => {
  backend.echoAndModify("test").then((resp) => {console.log(resp)})
})
```
`backend.waitInit` is only required if you want to immediately trigger some 
back-end function during initialization. Nimview takes a few milliseconds to 
load all functions from back-end to front-end.
You don't need this function if user action triggers a back-end call.

Keep also in mind that the inlined.html is completely "inlined" for release mode and that any "defer" 
keyword would not work for your script tags. So your javascript may be ready before
the DOM is ready for Jasascript. You may still trigger to load the 
javascript deferred when using 
```
document.addEventListener("DOMContentLoaded", function(event) { 
```
to init your javascript when the DOM is ready, for example in your "main.js" for Svelte or Vue.


## Exchange data with UI
Nimview register functions to take up to 4 arguments. If you need more or if you have 
more complex data, it is recommended to use Json to encode your values on the client. 
Use a parser on the back-end to read all values and send Json back to the client. By this, you have an unlimited amount of input and output
parameter values.
This is easy when using python or Nim as back-end. This may also simplify automated unit testing, as you can store the specific strings as Json 
and only check specific Json values.
Notice, that all registered functions return only strings, so the server will also just return a string value.
If you need Json, you need to parse this value in javascript manually, for example with JSON.parse().
In case you want to use C++ - don't write your own C++ Json parser. Feel free to use https://github.com/nlohmann/json. You might re-use it in other code locations.

It is also possible to call front-end functions directly from back-end by using
`callFrontendJs`. You may trigger an `alert("Hello World!")` on the frontend by 
using following Nim code:
```
  nimview.callFrontendJs("alert", "Hello World!")
```
in your back-end code. You may use as many parameters as you want.
This works directy for functions in the global js "window" namespace. If you need 
to call a local function, you need to register it first in javascript with 
`window.backend.mapFrontendFunction(<functionName>, function(parameter) {...})`.
You can then call it from back-end. 
Keep in mind to only use this to send visible information to the UI and not rely
your application workflow on this function. Otherwise, your application might 
become hard to test.

## Development workflow
You need to compile the back-end and usually the front-end too, when using vue or svelte. While this seems unnecessary complicated in the beginning, 
you will have the freedom to only restart the back-end if you have back-end changes and 
use some autoreload feature of webpack (vue) and rollup (svelte) for the frontend.

The setup/install with Svelte after installing nim would be: 
- `nimble install nimview`
- `npx degit marcomq/nimview/examples/svelte myProject`
- `cd myProject`
- `npm install`

To create a release version, just run
- `npm run build`
- `nim c -d:release --app:gui src/App.nim`

But if you want to change code easily, the development workflow would be:
- start your back-end in debug mode with vs code or terminal, run: 
- `nim c -r -d:debug src/App.nim`
- start your frontend npm in autoreload with VS-Code or terminal, run 
- `npm run dev`
- open a browser with url http://localhost:5000 to see the current front-end code result that is served by Node.js
- change your front-end code, the page will reload automatically
- change your back-end code and re-run `nim c -r -d:debug src/App.nim` or restart the VS Code debugger
- keep in mind that http://localhost:5000 is only a development url, the Javascript generated for production would be reachable by default at http://localhost:8000

You can also write simple integration tests with cypress using the debug (Webserver) mode.
This makes automated tests nearly as simple as for Electron.
Unfortunately, Cypress doesn't support IE11 and Nimview doesn't support Edge/Chromium on Windows yet.
But thx to babel, there aren't many JS incompatibilities. 
An Edge version of Nimview is already planned.

## Inline HTML to single binary
Nimview doesn't automatically create a single executable that contains the user interface 
for all possible scenarios. Nimview currently adds `../dist/inlined.html`
to the binary - and only in release mode. This HTML file shouldn't contain any 
external dependencies like css, images 
javascript as these wouldn't be included in the executable binary.
You can use an inliner to inline your external dependencies. Check the svelte_todo exampple
for this. There is a "npm build" command in packages.js which calls an inliner to
scan dist/index.html and write the output to `../dist/inlined.html`. For very small projects,
you may even use an inlined HTML file directly.

Keep in mind that these inlined HTML files might also be hard to debug if they contain
javascript - so you should still have some way to just open the un-inlined index.html file.

## Components as diagram

![nimview](https://user-images.githubusercontent.com/62469331/124002547-2ca26100-d9d6-11eb-955a-86954a016b69.png)


### Why Nim
Nim is actually some great "batteries included" helper. It is similar readable as python, has some cool Json / HTTP Server / Webview modules 
but creates plain C Code that can be compiled by gcc compilers to optimized machine code. 
You can also include C/C++ code as the output of Nim is just plain C. Additionally, it can be compiled to a python library easily. 
(https://robert-mcdermott.gitlab.io/posts/speeding-up-python-with-nim/).

### Which JS framework for UI
There are many JS frameworks to choose to create responsive user interfaces.
Svelte will create the fastest and best readable front-end code. But it is completely up to you which framework you will choose, as Vue and React have much more plugins and add-ons.

There is an example for Vue + Bootstrap 4 in tests/vue and one for Svelte in tests/svelte.
For the Windows target, you need to choose a IE 11 compatible CSS library. Bootstrap 5 
for example isn't compatible with IE 11 anymore.

### Nimview vs Electron or CEF
Electron and CEF are great frameworks with a lot of useful utilities and both were an inspiration to this helper here. 
However, the output binary of electron or CEF is usually more than 100 MB and getting started with a new project without previous knowledge of Electron / CEF can also take some time. 
Both CEF and Electron might be great for large Desktop projects that don't need to care about RAM + Disk or that require some additional custom window color,
task symbols or other features. 
But setting up Electron / CEF applications and deploying them takes a lot of knowledge and time, which you can safe by using this helper here.
The binary output of Nimview is usually less than 2 MB. If you zip the binary, you even have less than 1 MB for a desktop application with UI. It also might just run in the Cloud as there is an included webserver 
You might easily run the app in Docker. Getting started might just take some minutes and it will consume less RAM, 
less system resources and will start-up much quicker than an Electron or CEF App.
You might write the same Code and the same UI for your Cloud application as for your Desktop App.
Cypress integration tests might still work as Nimview has a webserver mode that can be used for testing. 

### Nimview vs Eel or Neel
There are another 2 cool similar frameworks: The very popular framework [eel](https://github.com/ChrisKnott/Eel) for python 
and its cousin [neel](https://github.com/Niminem/Neel) for nim. 
While the use case seems to be similar, there are some major differences: 
- With Nimview, you don't need a webserver running that might take requests from any other user on localhost as you use Webview in release mode. 
This improves security as you don't need to worry about open ports or other attack vectors that need to be considered when running a webserver application. It also makes it easy to run multiple applications without having port conflicts. For some security scenarios, using a webserver - even on localhost - might be not an option at all. 
You can use Nimview in suche a case, as you get a similar development experience but with less security concerns.
- Nimview also includes a simple global token check in release mode that may be able to prevent most
  CSRF attacks when the server is running on localhost.
 
### Difference to Flask
[Flask](https://github.com/pallets/flask) is probably the most popular python framework to create micro services and Nimview/AsyncHttpServer probably cannot compete with the easiness or with the amount of available plugins of Flask for simple python cloud applications. 
But the use-case is different. While flask was desinged to serve HTML and have easy RESTful routes for "get" and "post", Nimview was just designed to trigger user events from ajax using "post". Nimview will not support server side template engines as flask does. The front-end code needs to care of routes and rendering.

Nimview can also create static binaries that can run in a minimal tiny Docker container that doesn't even need an installed python environment, as long as no python code is used. So you might create containers for your application that have just a few MB. Those deploy and startup much faster than Flask applications. Make sure to avoid building with Webview when creating binaries for Docker by compiling with `-d:useServer`, or you need to include GTK libraries in your container.

### Wails
After releasing the first 0.1.0 version of Nimview, I found out about [Wails](https://github.com/wailsapp/wails). And I found out that I nearly created a Wails clone. Just - Wails had some nice additional features 
that Nimview didn't had. So - Wails became a big inspiration for Nimview 
Version 0.2.0: 
- Compilation to a single static binary was added,
- Multiple arguments for server functions were added and
- Server functions are automatically exposed to the client when registered on server
Version 0.3.0: 
- Calling JS functions directly from back-end

Nimview currently "borrows" its current Webview code from Wails, as the wails community still performs fixes
on the old C header-only version of Webview.

Nimview still has a smaller code base and creates even smaller binaries. You also have classical languages 
for your back-end as C, C++ or Python code - and you can mix those with Nim.
Additionally, Nimview supports Android for offline and online applications.

### CSRF and Security
Nimview was made with security in mind. For the Webview `startDesktop` mode, no network ports are opened to display the UI. The webserver is mostly for debugging and development.  
So the application doesn't need to be checked for several common attack vectors
of web-applications as long as Webview is used.

However, if you create a web-application, you need perform most security mitigations by yourself, by middleware or by the javascript framework you are using. 
You may check [owasp.org](owasp.org)

Following CSRF protections are already included in Nimview: 

Nimview stores 3 global random non-session tokens that renew each other every 60 seconds. A valid token is required for any Ajax request except "getGlobalToken". 
The token is queried automatically with a "getGlobalToken" request when the application starts. If the token is missing or wrong, there is a "403" error for ajax requests.

This isn't a full CSRF protection, as the token isn't bound to a session and all 
users that can read responses from localhost could also use this token to 
perform an attack (even if they may already send request directly to localhost).
If you add a "Samesite" directive for cookies, you might already prevent most common CSRF attack vectors.
The token check can also be disabled with `setUseGlobalToken(false)` for debugging, development,
or in case that there is already a session-based CSRF mitigation used by middleware. 

### Multithreading
Nimview was initially planned to run single-threaded. But calling back-end functions stopped Webview from updating the DOM.
Therefore, an additional Webview thread was added automatically that sends information back to the main thread with Nim Channels,
if the application was compiled with the option `threads:on`. On linux, it is also recommended to use `gc:orc` to avoid issues
with the Nim garbage collector. You can still enforce to use Nimview to be completely single threaded if you compile with 
`-d:useWebviewSingleThreaded`. 
Check the Nim manual on how to deal with multithreading and sharing data as multithreading is still complicate in Nim.

You may also use threads in Python or C++.

### IE 11 or - "Why is my page blank?"
Nimview uses IE 11 on Windows. Unfortunately, IE 11 doesn't understand modern Javascript
or ES6. Just writing modern Javascript will result in a blank white page. 
You therefore need to transform your code with Babel or other tools. 
Check the examples for this.
It might be possible to use Webview2 in future on Windows to get rid of IE 11, but this 
is depending on external Nim libraries that offer a wrapper for Webview. It wasn't tested yet,
but it may be possible to use GTK on Windows in case you really need to avoid IE 11.
At the time of writing, there is no simple and stable library supporting Webview 2 for Nim, 
and GTK on Windows was much more complicated as just using the IE 11 engine.
The examples mostly use `npm run dev` for daily development. These do not
compile for IE 11. If you use IE11, you need to run `npm run dev-ie`. This is not
the default, as the build takes much longer when using babel.

### Using UI from existing web-applications
For Desktop applications, it is required to use relative file paths in all your HTML. The paths must point to a directory relative of the binary to the given index html file.
It is not possible to use a subdirectory of the index file. You can also not use a web URL as startpoint, as this must be an existing file.
It is also not recommended to load from an untrusted URL from any existing internet source, as this could easily cause a security breach.
The Desktop mode is using IE11 as platform, so there might be security issues when loading uncontrolled content from internet.

## Software Requirements

```
- install nim (https://nim-lang.org/install.html)
    avoid white-space in nim install folder name when using windows
    add path by running nim "finish" in the nim install directory, so you have nimble available
    restart or open new shell to have nimble available
- linux: yum install gcc webkitgtk4-devel npm <or:> apt install gcc libwebkit2gtk-4.0-dev npm
- windows: install node > 12.19  (https://nodejs.org/en/download/)
- nimble install nimview
- (optional for C/C++ on Windows: install gcc / make sure that minGW is in your path)
- npx degit marcomq/nimview/examples/xxx myProject
```

### Documentation
A documentation is [here](https://htmlpreview.github.io/?https://github.com/marcomq/nimview/blob/master/docs/theindex.html)
