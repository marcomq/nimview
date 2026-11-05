# Nimview UI Library 
# © Copyright 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview


# Cocoa only allows creating windows on the main thread.
const useWebviewInThread* = compileOption("threads") and not defined(useWebviewSingleThreaded) and
    not defined(macosx)
when useWebviewInThread:
    import threadpool
import ../nimview/webview/webview except debug
import json
import logging as log
import nimpy, strutils
import globals
import dispatchJsonRequest

type WebviewRenderer = ref object
    webView*: Webview
    when useWebviewInThread:
        webviewQueue: Channel[string]
        runBarrier: Channel[bool]
        initBarrier: Channel[bool]


proc getInstance: ptr WebviewRenderer =
  {.gcsafe.}:
    if nimviewVars.webviewRenderer.isNil:
        var newObj {.global.} = new WebviewRenderer
        when useWebviewInThread:
            newObj.webviewQueue.open()
            newObj.runBarrier.open()
            newObj.initBarrier.open()
        GC_ref(newObj)
        nimviewVars.webviewRenderer = newObj.unsafeAddr
    return cast[ptr WebviewRenderer](nimviewVars.webviewRenderer)

proc computeMessageWebview(message: string)

proc evalJs*(evalJsCode: string) =
    if getInstance().webview.isNil:
        return
    getInstance().webview.dispatch(proc(w: Webview, js: string) {.nimcall.} =
        discard w.eval(js.cstring), evalJsCode)

proc callFrontendJsEscapedWebview*(functionName: string, params: string) =
  ## "params" should be JS escaped values, separated by commas with surrounding quotes for string values
  {.gcsafe.}:
    if not getInstance().webview.isNil:
        let jsExec: string = "window.ui.callFunction(\"" & functionName & "\"," & params & ");"
        log.info jsExec
        evalJs(jsExec)

proc stopDesktop*() {.exportpy, exportc: "nimview_$1".} =
    ## Will stop the Desktop app - may trigger application exit.
    debug "stopping ..."
    if not getInstance().webview.isNil():
        getInstance().webview.dispatch(proc(w: Webview, arg: string) {.nimcall.} =
            w.terminate(), "")

proc destroyDesktop() =
    ## Must only be called after the webview loop has finished.
    let w = getInstance().webview
    if not w.isNil():
        getInstance().webview = nil
        when not defined(macosx):
            w.exit() # Cocoa would terminate the whole app here
        dealloc(w)

proc runDesktop*(url: string, title: string, width: int, height: int, 
    resizable: bool, debug: bool, run: bool)  =  
    {.gcsafe.}:
        if getInstance().webview.isNil:
            getInstance().webview = webview.newWebView(title, url, width,
                height, resizable = resizable, debug = debug)
        getInstance().webview.bindProc("nimview", "alert", proc (message: string) =
            getInstance().webview.info("alert", message))
        let dispatchCall = proc (message: string) =
            when useWebviewInThread:
                getInstance().webviewQueue.send(message)
            else:
                computeMessageWebview(message)
        getInstance().webview.bindProc("nimview", "call", dispatchCall)
        when useWebviewInThread:
            getInstance().initBarrier.send(true)
            if not run:
                discard getInstance().runBarrier.recv()
            getInstance().webview.run()
            getInstance().webviewQueue.send("")
            getInstance().runBarrier.close()
            getInstance().initBarrier.close()
            destroyDesktop()


proc spawnDesktopThread*(url: string, title: string, width: int, height: int, 
    resizable: bool, debug: bool, run: bool)  =
    when useWebviewInThread:
        spawn runDesktop(url, title, width, height, resizable, debug, run)
        discard getInstance().initBarrier.recv()
    
proc waitForThreads*() =
    when useWebviewInThread:
        sync()

proc runWebview*() = 
    when useWebviewInThread:
        # actual webview is currently waiting in "runDesktop"
        getInstance().runBarrier.send(true)
        while nimviewSettings.run:
            var message = getInstance().webviewQueue.recv()
            computeMessageWebview(message)
    else:
        getInstance().webview.run()
        destroyDesktop()


proc selectFolderDialog*(title: string): string  {.exportpy.} =
    ## Will open a "sect folder dialog" if in webview mode and return the selection.
    ## Will return emptys string in webserver mode
    if not getInstance().webview.isNil():
        result = getInstance().webview.dialogOpen(title=if title != "" : title else: "Select Folder", flag=webview.dFlagDir)
    
proc selectFileDialog*(title: string): string  {.exportpy.} =
    ## Will open a "sect file dialog" if in webview mode and return the selection.
    ## Will return emptys string in webserver mode
    if not getInstance().webview.isNil():
        result = getInstance().webview.dialogOpen(title=if title != "" : title else: "Select File", flag=webview.dFlagFile)

proc setIcon*(icon: string) {.exportpy.} = 
    getInstance().webview.dispatch(proc(w: Webview, icon: string) {.nimcall.} =
        w.setIcon(icon.cstring), icon)
    
proc setBorderless*(decorated: bool = false) {.exportc, exportpy.} =
    ## Use gtk mode without borders, only works on linux and only in desktop mode
    when defined(linux): 
        let myWebView = getInstance().webview
        if not myWebView.isNil():
            {.emit: "gtk_window_set_decorated(GTK_WINDOW(`myWebView`->priv.window), `decorated`);".}

proc setFullscreen*(fullScreen: bool = true) {.exportc, exportpy.} =
    if not getInstance().webview.isNil():
        getInstance().webview.dispatch(proc(w: Webview, arg: string) {.nimcall.} =
            discard w.setFullscreen(arg == "true"), $fullScreen)

proc setColor*(r, g, b, alpha: uint8) {.exportc, exportpy.} =
    if not getInstance().webview.isNil():
        getInstance().webview.dispatch(proc(w: Webview, arg: string) {.nimcall.} =
            let c = arg.split(',')
            w.setColor(c[0].parseInt.uint8, c[1].parseInt.uint8, c[2].parseInt.uint8, c[3].parseInt.uint8),
            [$r, $g, $b, $alpha].join(","))

proc setMaxSize*(width, height: int) {.exportpy.} =
    if not getInstance().webview.isNil():
        getInstance().webview.dispatch(proc(w: Webview, arg: string) {.nimcall.} =
            let size = arg.split(',')
            w.setMaxSize(size[0].parseInt.cint, size[1].parseInt.cint), $width & "," & $height)
    
proc setMaxSize*(width, height: cint) {.exportc.} =
    setMaxSize(width.int, height.int)

proc setMinSize*(width, height: int) {.exportpy.} =
    if not getInstance().webview.isNil():
        getInstance().webview.dispatch(proc(w: Webview, arg: string) {.nimcall.} =
            let size = arg.split(',')
            w.setMinSize(size[0].parseInt.cint, size[1].parseInt.cint), $width & "," & $height)
    
proc setMinSize*(width, height: cint) {.exportc.} =
    setMinSize(width.int, height.int)

proc focus*(width, height: int) {.exportpy, exportc.} =
    if not getInstance().webview.isNil():
        getInstance().webview.dispatch(proc(w: Webview, arg: string) {.nimcall.} =
            w.focus(), "")

proc computeMessageWebview(message: string) {.used.} =
    info message
    if message.len == 0:
        nimviewSettings.run = false
    else:
        let jsonMessage = json.parseJson(message)
        let requestId = jsonMessage["requestId"].getInt()
        try:
            let response = dispatchJsonRequest(jsonMessage)
            let evalJsCode = "window.ui.applyResponse(" & $requestId & "," & 
                response.escape("'","'") & ");" 
            evalJs(evalJsCode)
        except: 
            log.error getCurrentExceptionMsg()
            let evalJsCode = "window.ui.rejectResponse(" & $requestId & ");"
            evalJs(evalJsCode)