# nimview_android
A Nim/Webview based helper to create Android applications with Nim/C/C++ and HTML/CSS

Android Studio implementation of [Nimview](https://github.com/marcomq/nimview)

This project uses Android Webview as UI layer. The back-end is supposed to be written in Nim, C/C++
or - if it doesn't need to be ported to other platforms - Kotlin or Java.
As Android Webview doesn't has as much debugging capabilities as Chrome or Firefox, it would be recommended to write most of the UI in a web application 
with nimview in debug mode + npm autoreload first and then test these changes on Android later.

The Nimview folder is in android/app/src/main/nim

The recommended workflow would be:
```
(installation)
npx degit marcomq/nimview/examples/android myAndroid
cd app/src/main/nim
nimble install -d -y
npm install


(development)
(open two terminals/shells, t1 and t2)
t1: nim cpp -r -d:useServer src/App.nim
t2: npm run dev
open browser at http://localhost:5000
(optional) modify nim / html / js code in VSCode
restart nim server to apply changes on nim code
press F5 if browser doesn't refresh automatically after js changes

(release and testing)
compile project with android studio, test, perform changes if required

```