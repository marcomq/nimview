# Nimview
A lightweight cross platform UI library for Nim, C, C++ or Python. The main purpose is to simplify creation of online / offline Desktop applications based on a HTML/CSS/JS layer to be displayed with Webview while also having the possibility to run the same applicatio on cloud with the same code.

# About

The target of this project is to have a simple, ultra lightweight cross platform, cross programming language UI layer for Desktop and Cloud applications that have just a few MB in static executable size. 
The UI layer will be completely HTML/CSS/JS based and the back-end should be using either Nim, C/C++ or Python code directly. 
Nim also acts as a "glue" layer as it makes it very easy to create python libs and can also create c libraries easily. 
The final result should be a binary executable that runs on Linux, Windows or (untested) MacOS  without the requirement to have some kind of web-server running. 
Running remote (cloud) server applications are possible too, but should use an additional authentication and security reverse proxy layer. An Android Studio setup for nimview is here: ...

Node.js is recommended if you want to build your Javascript UI layer with Svelte/Vue/React or the framework of your choice.
During development in debug mode, the back-end code will also create a simple HTTP server by default, so you can use all your usual debugging and development tools in Chrome or Firefox. 
Webview on its own is a mess if you want to debug your Javascript issues.

This project is not intended to have any kind of forms, inputs or any additional helpers to create the UI. 
If you need HTML generators or helpers, there are widely used open source frameworks available, for example Vue-Bootstrap (https://bootstrap-vue.org/).

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

## HTML/JS client side (only the important part)
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
This is not expected to work with Svelte, as the modification of the object would be hidden for Svelte.

You need to include your own error handler in the callback, as there is no separate error callback function.


## Does this mean I can only send just 1 value and just receive just 1 value from back-end?
Yes and No - you can use Json to encode your values on the client, use a parser on the back-end to read all values and send Json back to the client. This is amazingly easy when using python or Nim as back-end. 
In case you want to use C++ - don't write your own C++ Json parser. Feel free to use https://github.com/nlohmann/json. You might re-use it in other code locations.

## Development Workflow
You need to compile the back-end and usually the front-end too, when using vue or svelte. While this seems unnecessary complicated, you will have the freedom to restart the back-end if you have back-end changes and 
may have an auto-updated browser UI immediately after file change as there is some great autoreload functionality for webpack (vue) and rollit (svelte).
So the development workflow would be:
- start your back-end in debug mode with vs code or terminal, run: `nimble debug && ./nimview_debug`
- start your frontend npm in autoreload with vs code or terminal, run `npm run dev --prefix <path_to_ui_folder>`
- open a browser with url http://localhost:5000 to see the current front-end code result that is served by node.js
- change your front-end code, the page will reload automatically
- change your back-end code and use the debug restart button in vs code when finished
- keep in mind that http://localhost:5000 is only a development url, the Javascript generated for production would be reachable by default at http://localhost:8000

### Why Nim?
Nim is actually some great "batteries included" helper. It is similar readable as python, has some cool Json / HTTP Server / Webview modules but creates plain C Code that can be compiled by gcc compilers to optimized machine code. 
You can also include C/C++ code as the output of Nim is just plain C. Additionally, it can be compiled to a python library easily. (https://robert-mcdermott.gitlab.io/posts/speeding-up-python-with-nim/).

### Which JS framework would be recommended.
If you work on Windows, Vue is probably the easiest to setup. There is an example for Vue + Bootstrap in tests/vue and also one example for Svelte in tests/svelte.
Svelte is probably fastest, easiest to write and best to read, but might create issues with the IE11 engine if you don't setup polyfill and babel correctly.
I already used to work with React and Redux. I really liked the advantage of using modules and using webpack, but I didn't like the verbosity of React or writing map-reducers for Redux. But if you want - you might just use the JS framework of your choice.
The main logic is in nimview.nim and backend-helper.js. Make sure to include backend-helper.js either in the static HTML includes. There is a minimal sample in tests/minimal_sample.nim that doesn't need any additionl JS library. 

### Why not Electron or CEF?
Electron is a great framework and it was also an inspiration to this helper here. However, using C++ Code is quite complicate in Electron. In CEF, it is easy to use C++, but the output binary is usually more than 100 MB and getting started with a new project can take some time. So, CEF might be great for large Desktop projects that don't need to care about RAM or Disk, but can be an overkill for small applications.
The output of this tool here can be less than 2MB. It also might just run in the Cloud as there is an included webserver - you might easily run the app in Docker. Getting started might just take some minutes and it will consume less RAM, less system resources and will start much quicker than an Electron or CEF App.
Also, you will have all the included features of nim if you decide to build a C++ Code. You might write the same Code and the same UI for your Cloud application as for your Desktop App.

### Difference to Eel and Neel
There are some cool similar frameworks: The very popular framework "eel" (https://github.com/ChrisKnott/Eel) for python and its little brother neel (https://github.com/Niminem/Neel) for nim
There are 2 major differences: 
- Both eel and neel make it easy to call back-end side functions from Javascript and also call exposed Javascript from back-end. This is not any goal here with Nimview. 
  Nimview will just make it easy to trigger back-end routes from Javascript but will not expose Javascript functions to the back-end side. 
  If you want to do so, you need to parse the back-end’s response and call the function with this data. This makes it possible to use multiple HTML / JS user interfaces for the same back-end code without worrying about javascript functions.
- With Nimview, you also don't need a webserver running that might take requests from any other user on localhost. This improves security and makes it possible to run multiple applications without having port conflicts.

### Difference to Flask
Flask is probably the most popular python framework to create micro services (https://github.com/pallets/flask) and nimview/Jester probably cannot compete with Flask for cloud applications. 
Nimview will also not support server side template engines as flask does. But in case you want your application also running on the Desktop or Mobile, or if you want to use nim or C++ as your primary language, you might get get your application done really quick when using nimview.

### IE 11 
Unfortunately, the backend-helper.js cannot send AJAX reuqests to a back-end, as IE 11 doesn't support fetch. I might add an alternative fetch support for IE 11 in case that IE 11 still exits when nimview gets popular. 
Feel free to make a PR if you need the IE 11 support sooner for your web engine.

## Project setup
```
- install nim (https://nim-lang.org/install.html or package manager)
    avoid white-space in nim install folder name when using windows
    add path by running nim "finish" in the nim install directory, so you have nimble available
    restart or open new shell to have nimble available
- nimble release
- (linux, optional if not installed by nimble: yum install nim, gcc, npm, webkit2gtk3-devel <or:> apt install nim, gcc, npm, libwebkit2gtk-4.0-dev
- install node > 12.19 if using windows  (https://nodejs.org/en/download/)
- run "cd tests/vue", "npm install" and "cd ../.." 
- run nimview
```
