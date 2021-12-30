# Nimview UI Library 
# © Copyright 2021, by Marco Mengelkoch
# Licensed under MIT License, see License file for more details
# git clone https://github.com/marcomq/nimview


const useWebviewInThread* = compileOption("threads") and not defined useWebviewSingleThreaded
when useWebviewInThread:
    import threadpool
when defined webview2:   
    {.warning:  "Warning: Webview 2 is not stable yet!" .}
    import ../nimview/webview2/src/webview except debug
else:
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
    when not defined webview2: 
        getInstance().webview.dispatch(proc() =
            discard getInstance().webview.eval(evalJsCode.cstring))
    else:
        getInstance().webview.eval(evalJsCode.cstring)

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
        when not defined webview2:
            getInstance().webview.dispatch(proc() = 
                getInstance().webview.terminate()
                dealloc(getInstance().webview))
        else:
            getInstance().webview.terminate()
            dealloc(getInstance().webview)

proc runDesktop*(url: string, title: string, width: int, height: int, 
    resizable: bool, debug: bool, run: bool)  =  
    {.gcsafe.}:
        if getInstance().webview.isNil:
            getInstance().webview = webview.newWebView(title, url, width,
                height, resizable = resizable, debug = debug)
        when not defined webview2:
            getInstance().webview.bindProc("nimview", "alert", proc (message: string) =
                getInstance().webview.info("alert", message))
            let dispatchCall = proc (message: string) =
                when useWebviewInThread:
                    getInstance().webviewQueue.send(message)
                else:
                    computeMessageWebview(message)
            getInstance().webview.bindProc("nimview", "call", dispatchCall)
        else: # webview2
            let dispatchCall = proc (jsonMessage: JsonNode) =
                when useWebviewInThread:
                    webviewQueue.send(message)
                else:
                    computeMessageWebview($jsonMessage)
            getInstance().webview.bindProc("nimview.call", dispatchCall)
        when useWebviewInThread:
            getInstance().initBarrier.send(true)
            if not run:
                discard getInstance().runBarrier.recv()
            getInstance().webview.run()
            getInstance().webviewQueue.send("")
            getInstance().runBarrier.close()
            getInstance().initBarrier.close()
            stopDesktop()


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
        stopDesktop()


when not defined webview2:
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
        getInstance().webview.dispatch(proc() = 
            getInstance().webview.setIcon(icon.cstring))
        
    proc setBorderless*(decorated: bool = false) {.exportc, exportpy.} =
        ## Use gtk mode without borders, only works on linux and only in desktop mode
        when defined(linux): 
            let myWebView = getInstance().webview
            if not myWebView.isNil():
                {.emit: "gtk_window_set_decorated(GTK_WINDOW(`myWebView`->priv.window), `decorated`);".}

    proc setFullscreen*(fullScreen: bool = true) {.exportc, exportpy.} =
        if not getInstance().webview.isNil():
            getInstance().webview.dispatch(proc() = 
                discard getInstance().webview.setFullscreen(fullScreen))

    proc setColor*(r, g, b, alpha: uint8) {.exportc, exportpy.} =
        if not getInstance().webview.isNil():
            getInstance().webview.dispatch(proc() = 
                getInstance().webview.setColor(r, g, b, alpha))

    proc setMaxSize*(width, height: int) {.exportpy.} =
        if not getInstance().webview.isNil():
            getInstance().webview.dispatch(proc() = 
                getInstance().webview.setMaxSize(width.cint, height.cint))
        
    proc setMaxSize*(width, height: cint) {.exportc.} =
        setMaxSize(width.int, height.int)

    proc setMinSize*(width, height: int) {.exportpy.} =
        if not getInstance().webview.isNil():
            getInstance().webview.dispatch(proc() = 
                getInstance().webview.setMinSize(width.cint, height.cint))
        
    proc setMinSize*(width, height: cint) {.exportc.} =
        setMinSize(width.int, height.int)

    proc focus*(width, height: int) {.exportpy, exportc.} =
        if not getInstance().webview.isNil():
            getInstance().webview.dispatch(proc() = 
                getInstance().webview.focus())
  
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