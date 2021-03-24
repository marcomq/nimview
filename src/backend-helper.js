// This file is supposed to be copied automatically to the UI folder, if it doesn't exists there yet

let ui = {};
let defaultPostTarget = "";
let host = ""; // might cause "cors" errors if defined
ui.responseStorage = {};
ui.responseCounter = 0;
/***
 * Generalized request pre-processing
 * Creates a standartized json object to be sent to server and also stores an internal object to handle the response
 * 
 *  request: will be sent to server as json ".request"
 *  data: can be either following: 
 *        1. a normal value, could be even json, which is then transmitted normally 
 *        2. a json object, which will require the "callbackFunction" to be the key and a non-function value. This will automatically create a callback that sets data[key] = response
 *        3. a function, in case you don't need to send data
 *  callbackFunction: will be a generalized callback for success and error. Will have the backend response as parameter. You will need to handle error and success manually.
 ***/
ui.createRequest = function(request, data, callbackFunction) {
  var key = request;
  switch (typeof data) {
    case 'object': 
      if ((typeof callbackFunction !== 'undefined') && 
          (typeof callbackFunction !== 'function') && 
          (callbackFunction in data)) {
        var key = callbackFunction;
        var outputValueObj = data;
        callbackFunction = function(response) { outputValueObj[key] = response; }; 
        data = data[key];
      }
      else {
        data = JSON.stringify(data);
      }
      break;
    case 'function': 
        callbackFunction = data; 
        data = '';
        break;
    case 'undefined': 
        data = '';
        break;
    default: 
      data = '' + data; 
      break;
  }
  if (ui.responseCounter >= Number.MAX_SAFE_INTEGER-1) {
    ui.responseCounter = 0;
  }
  var storageIndex = ui.responseCounter++;
  ui.responseStorage[storageIndex] = new Object(
    {'request': request, 'responseId': storageIndex, 'callbackFunction': callbackFunction}
  );
  var jsonRequest = {'request': request, 'value': data, 'responseId': storageIndex, 'key': key};
  return jsonRequest;
};

/***
 * Generalized request post-processing
 * Maps the previous requestId to an object and applies the (async) response to this object
 ***/
ui.applyResponse = function(value, responseId) {
  var storedObject = ui.responseStorage[responseId];
  var result;
  if (typeof storedObject.callbackFunction === 'function') {
    result = storedObject.callbackFunction(value);
  }
  delete ui.responseStorage[responseId];
  return result
};

/*global backend*/
ui.alert = function (str) {
  if (typeof backend === 'undefined') {
    alert(str);
  }
  else {
    backend.alert(str);
  }
}
/***
 * Send something to backend. Will automatically chose webview if available. * 
 *  request: will be sent to server as json ".request"
 *  data: can be either following: 
 *        1. a normal value, could be even json, which is then transmitted normally 
 *        2. a json object, which will require the "callbackFunction" to be the key and a non-function value. 
 *           This will automatically create a callback that sets data[key] = response
 *        3. a function, in case you don't need to send data
 *  callbackFunction: will be a generalized callback for success and error. Will have the backend response as parameter.
 *        You will need to handle error and success manually.
 ***/
ui.backend = function (request, data, callbackFunction) {
  var jsonRequest = { responseId: 0 };
  if (typeof backend === 'undefined') {
  // Simulate running in Webview, but using a HTTP server
  // It will not be possible to use MS Edge for debugging, as this has similar identifiers as Webview on Windows 
  // query server with HTTP instead of calling webview callback
    jsonRequest = ui.createRequest(request, data, callbackFunction);
    var postData = JSON.stringify(jsonRequest);
    if (defaultPostTarget == "") {
      var url = request; // Not required. Just for easier debugging
    }
    else {
      var url = defaultPostTarget; 
    }
    var responseHandler = function(response) {
      var key = jsonRequest.key;
      if ((typeof response === "object") && (key in response)) {
        ui.applyResponse(response[key], jsonRequest.responseId);
      }
      else {
        ui.applyResponse(response, jsonRequest.responseId);
      }

    };
    if (typeof fetch !== "undefined") { // chrome and other modern browsers
      var opts = {
        method: 'POST', // always use AJAX post for simplicity with special chars    
        mode: 'cors',
        cache: 'no-cache',
        headers: {'Content-Type': 'application/json'},
        body: postData
      };
      if (ui.globalToken && (ui.globalToken.length > 0)) {
        opts.headers["global-token"] = ui.globalToken;
      }
      fetch(host + "/" + url, opts).then(function(response) {
        if (response) {
          var globalToken = response.headers.get("global-token");
          if (globalToken && (globalToken.length > 0)) {
            ui.globalToken = globalToken;
            ui.lastToken = Date.now();
          }
          if (response.json) {
            return response.json();
          }
        }
        return response;
      }).then(responseHandler).catch(function(err) {
        if (console && console.log) {
          console.log(err);
        }
      });
    }
    else { // IE11
      let xhr = new XMLHttpRequest();
      xhr.open('POST', host + "/" + url, true);
      if (ui.globalToken && (ui.globalToken.length > 0)) {
        xhr.setRequestHeader("global-token", ui.globalToken);
      }
      xhr.responseType = "json";
      xhr.onreadystatechange = function() {
        if (xhr.readyState !== 4) {
          return; // not finished yet, check next state
        }
        if (xhr.status === 200) {
          // request successful - show response
          var response = xhr.response;
          var globalToken = xhr.getResponseHeader("global-token");
          if (globalToken && (globalToken.length > 0)) {
            ui.globalToken = globalToken;
          }
          if (typeof response === "string") {
            responseHandler(JSON.parse(response));
          }
          else {
            responseHandler(response);
          }
        }
        else {
          // request error
          if (console && console.log) {
            console.log('HTTP error', xhr.status, xhr.statusText);
          }
        }
      };
      xhr.send(postData);
    }
  }
  else {
    // This part of the function is intendend to interact directly with webview. No HTTP server involved.
    // There will be an async call on the backend server, which is then triggering to call javascript from webview.
    // This callback function will be stored in a container ui.responseStorage. Nim Webview had issues calling javascript on Windows
    // at the time of development and therefore required an async approach that doesn't use the async keyword and can't await.
      jsonRequest = ui.createRequest(request, data, callbackFunction);
      var response = backend.call(JSON.stringify(jsonRequest));
      if (typeof response !== "undefined") {
        var key = jsonRequest.key;
        if ((typeof response === "object") && (key in response)) {
          ui.applyResponse(response[key], jsonRequest.responseId);
        }
        else {
          ui.applyResponse(response, jsonRequest.responseId);
        }
      }
 
    }
  }
// "import from" doesn't seem to work with webview here... So add this as global variable
ui.getGlobalToken = function() {
  if (typeof backend === 'undefined') {
    if ((typeof ui.lastToken === 'undefined') || 
        (ui.lastToken + (60 * 1000) <= Date.now())) {
      ui.backend("getGlobalToken");
    }
  }
};
window.setTimeout(ui.getGlobalToken, 150);
window.setInterval(ui.getGlobalToken, 60 * 1000);
window.ui = ui;