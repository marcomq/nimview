# Webview for nim

Nim bindings for [Webview](https://github.com/webview/webview) - A tiny 
cross-platform webview library for C/C++/Golang to build modern cross-platform 
GUIs. 

Preview generated nimterop wrapper with:
```
nim r -f -d:printWrapper src/webview.nim
```

# Docs

Documentation is [here](http://htmlpreview.github.io/?https://github.com/oskca/webview/blob/master/docs/webview.html)

and [Golang's doc for webview](https://godoc.org/github.com/zserge/webview) is
also very useful.

When on `debian/ubuntu` `libwebkit2gtk-4.0-dev` is required as `debian/ubuntu`.

# git commands
initial: 
```
git subtree add --prefix src/webview/webview  https://github.com/webview/webview.git master --squash
```
pull latest:
```
git subtree pull --prefix src/webview/webview  https://github.com/webview/webview.git master --squash
```