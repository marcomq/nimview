/** Nimview UI Library 
 * © Copyright 2021, by Marco Mengelkoch
 * Licensed under MIT License, see License file for more details
 * git clone https://github.com/marcomq/nimview
**/

import "whatwg-fetch"

let ui
if (typeof window.ui !== "object") {
    ui = {}
    ui.copyright = "© Copyright 2021, by Marco Mengelkoch"
    ui.resolveStorage = {}
    ui.requestCounter = 0
    ui.initStarted = false
    ui.initFinished = false
    ui.initFailed = false
    window.ui = ui
}
else {
    ui = window.ui
}
let backend
if (typeof window.backend !== "object") { 
    backend = {}
    window.backend = backend
}
else {
    backend = window.backend
}
const defaultPostTarget = ""
const host = "" // might cause "cors" errors if defined

ui.createRequestId = () => {
    if (ui.requestCounter >= Number.MAX_SAFE_INTEGER-1) {
        ui.requestCounter = 0
    }
    return ui.requestCounter++
}

ui.alert = (str) => {
    if (typeof window.nimview === 'undefined') {
      alert(str)
    }
    else if (typeof window.nimview.alert === 'function') {
        window.nimview.alert(str)
    }
}
ui.callRequest = async (request, signature, data) => {
    if (typeof signature === "undefined") {
        signature = ""
    }
    if (typeof data === "undefined") {
        data = []
    }
    if (typeof window.nimview === 'undefined') {
        // http-server
        const postData = JSON.stringify({request: request, data: data})
        const requestOpts = { 
            method: 'POST', // always use AJAX post for simplicity with special chars    
            mode: 'cors',
            cache: 'no-cache',
            headers: {'Content-Type': 'application/json'},
            body: postData
        }
        let url = request
        if (defaultPostTarget != "") {
            url = defaultPostTarget
        }
        if (ui.globalToken && (ui.globalToken.length > 0)) {
            requestOpts.headers["global-token"] = ui.globalToken
        }
        if (data.length != Math.min(signature.length, signature.split(",").length) && console && console.log) {
            console.log("Request signature might not fit: '" + request + "' signature: '" + signature + "' data: '" + JSON.stringify(data) + "'") 
        }
        return fetch(host + "/" + url, requestOpts).then((response) => {
            if (response) {
                var globalToken = response.headers.get("global-token")
                if (globalToken && (globalToken.length > 0)) {
                ui.globalToken = globalToken
                ui.lastToken = Date.now()
                }
            }
            return response.text()
        })
    }
    else {
        // webview
        if (typeof window.nimview.call === "function") {
            const requestId = ui.createRequestId()
            const postData = JSON.stringify({request: request, data: data, requestId: requestId})
            let promise = new Promise((resolve, reject) => {
                ui.resolveStorage[requestId] = [resolve, reject]
                let response = window.nimview.call(postData)
                if (typeof response !== "undefined") {
                    // android webview
                    resolve(response)
                    delete ui.resolveStorage[requestId]
                }
            })
            return promise
        }
    }
}

ui.addRequest = (requestOrArray) => {  
    /*register global backend functions*/
    if (typeof requestOrArray === "string") {
        requestOrArray = [requestOrArray, ""]
    }
    let request = requestOrArray[0] + ""
    let signature = requestOrArray[1]  + "" // for debugging
    backend[request] = async (...data) => {
        return ui.callRequest(request, signature, data)
    }
}

ui.applyResponse = (requestId, data) => {
    if (typeof ui.resolveStorage[requestId] !== "undefined") {
        ui.resolveStorage[requestId][0](data)
        delete ui.resolveStorage[requestId]
    }
    else {
        ui.alert("request id '" + requestId + "' not found")
    }
}
ui.rejectResponse = (requestId) => {
    if (typeof ui.resolveStorage[requestId] !== "undefined") {
        ui.resolveStorage[requestId][1]()
        delete ui.resolveStorage[requestId]
    }
}
ui.initRequests = (async () => {
    if (ui.initStarted == false) {
        ui.initStarted = true
        await ui.callRequest("getGlobalToken", "", []).then((resp) => {
            let jsResp = JSON.parse(resp)
            if (jsResp.useGlobalToken) {
                window.setInterval(ui.getGlobalToken, 60 * 1000)
            }
        }).catch(() => {
            ui.alert("getGlobalToken failed")
            ui.initFailed = true
        })
        await ui.callRequest("getRequests", "", []).then((resp) => {
            let jsResp = JSON.parse(resp)
            for (let req of jsResp) { // req is type array
                // bind all server requests to window.backend
                ui.addRequest(req)
            }
            ui.initFinished = true
        }).catch(() => {
            ui.alert("getRequests failed")
            ui.initFailed = true
        })
    }
})
/**
 * This call is optional. You need to call this function if you want to 
 * immediately call a backend function and need to make sure that all functions
 * are already available. 
 * In case you need to wait for initalization, call:
 * await backend.waitInit()
 * or
 * backend.waitInit().then(backend.functionThatNeedsToWait)
 */
backend.waitInit = () => {
    // everything else was complicate when using webview on windows
    return new Promise((resolve, reject) => {
        let waitLoop = () => {
            if (ui.initFinished) {
                return resolve()
            }
            else if (ui.initFailed) {
                return reject()
            }
            else {
                setTimeout(waitLoop, 5)
            }
        }
        setTimeout(waitLoop, 1)
    })
}
window.setTimeout(ui.initRequests, 1) // may need to be increased on webview error
export default backend