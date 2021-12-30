import os
{.passC: "-DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION".}
const webviewPath = currentSourcePath().parentDir() / "webview"
{.passC: "-I" & webviewPath & "/" .}

when defined(linux):
  {.passC: "`pkg-config --cflags gtk+-3.0 webkit2gtk-4.0`".}
  {.passL: "`pkg-config --libs gtk+-3.0 webkit2gtk-4.0`".}
elif defined(macosx):
  {.passL: "-framework WebKit".}
elif defined(windows):  
  {.passC: "-I" & webviewPath & "/script/microsoft.web.webview2.1.0.664.37/build/native/include" .}
  {.passC: "-DWEBVIEW_WINAPI=1".}
  {.passC: "-DWEBVIEW_HEADER" .}
  when defined(cpp) and defined(VCC):
    {.passC: "/std:c++17" .}
    {.compile("webview/webview.cc", "-UWEBVIEW_HEADER").} # creates warning D9025
    {.passL: webviewPath & "/script/microsoft.web.webview2.1.0.664.37/build/native/x64/WebView2LoaderStatic.lib version.lib Shell32.lib".}
    static: 
      echo "Using MSVC, building static binary"
  else:
    {.passL: "-L" & webviewPath & "/dll/x64 -lwebview".}
    # TODO: call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\Tools\vsdevcmd.bat" to find includes
    # TODO: copy dll to target dir
    static: 
      echo "Not building static binary, use `nim cpp --cc:vcc` to build statically"
type
  ccstring* {.importc: "const char*".} = cstring
  Webview* {.importc: "webview_t",  header: "webview.h".} = pointer
  WebviewCb = proc(seq: ccstring, req: ccstring, arg: pointer){.cdecl.}

{.push header: "webview.h", cdecl.}
proc create*(debug:cint, window:pointer): Webview{.importc: "webview_create".}
  ##   Creates a new webview instance. If debug is non-zero - developer tools will
  ##      be enabled (if the platform supports them). Window parameter can be a
  ##      pointer to the native window handle. If it's non-null - then child WebView
  ##      is embedded into the given parent window. Otherwise a new window is created.
  ##      Depending on the platform, a GtkWindow, NSWindow or HWND pointer can be
  ##      passed here.
proc destroy*(w: Webview){.importc: "webview_destroy".}
  ##   Destroys a webview and closes the native window.
proc run*(w: Webview){.importc: "webview_run".}
  ##   Runs the main loop until it's terminated. After this function exits - you
  ##      must destroy the webview.
proc terminate*(w: Webview) {.importc: "webview_terminate"}
  ##   Stops the main loop. It is safe to call this function from another other
  ##      background thread.
proc dispatch*(w: Webview, fn: proc (w: Webview, arg: pointer) {.cdecl.},
               arg: pointer) {.importc: "webview_dispatch".}
  ##   Posts a function to be executed on the main thread. You normally do not need
  ##      to call this function, unless you want to tweak the native window.
proc get_window*(w: Webview): pointer {.importc: "webview_get_window".}
  ##   Returns a native window handle pointer. When using GTK backend the pointer
  ##      is GtkWindow pointer, when using Cocoa backend the pointer is NSWindow
  ##      pointer, when using Win32 backend the pointer is HWND pointer.
proc set_title*(w: Webview, title: cstring){.importc: "webview_set_title".}
  ##   Updates the title of the native window. Must be called from the UI thread.
proc set_size*(w: Webview, width, height, hints: cint)
              {.importc: "webview_set_size".}
  ##   Updates native window size. See WEBVIEW_HINT constants.
proc navigate*(w: Webview; url: cstring) {.importc: "webview_navigate".}
  ##   Navigates webview to the given URL. URL may be a data URI, i.e.
  ##      "data:text/text,<html>...</html>". It is often ok not to url-encode it
  ##      properly, webview will re-encode it for you.
proc init*(w: Webview, js: cstring){.importc: "webview_init".}
  ##   Injects JavaScript code at the initialization of the new page. Every time
  ##      the webview will open a the new page - this initialization code will be
  ##      executed. It is guaranteed that code is executed before window.onload.
proc eval*(w: Webview, js: cstring){.importc: "webview_eval".}
  ##   Evaluates arbitrary JavaScript code. Evaluation happens asynchronously, also
  ##      the result of the expression is ignored. Use RPC bindings if you want to
  ##      receive notifications about the results of the evaluation.
proc bindCb*(w: Webview, name: cstring, cb: WebviewCb, arg: pointer) 
            {.importc: "webview_bind" .}
  ##   Binds a native C callback so that it will appear under the given name as a
  ##      global JavaScript function. Internally it uses webview_init(). Callback
  ##      receives a request string and a user-provided argument pointer. Request
  ##      string is a JSON array of all the arguments passed to the JavaScript
  ##      function.
proc returnCb*(w: Webview; seq: cstring; status: cint; result: cstring) 
              {.importc: "webview_return"}
  ##   Allows to return a value from the native binding. Original request pointer
  ##      must be provided to help internal RPC engine match requests with responses.
  ##      If status is zero - result is expected to be a valid JSON result value.
  ##      If status is not zero - result is an error JSON object.
{.pop.}

