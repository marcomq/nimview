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
 *  callbackFunction: 
 ***/
ui.createRequest = function(request, data, callbackFunction) {
  var key = request;
  switch (typeof data) {
    case 'object': 
      if ((typeof callbackFunction !== 'undefined') && (typeof callbackFunction !== 'function') && (callbackFunction in data)) {
        var key = callbackFunction;
        var outputValueObj = data;
        callbackFunction = function(response) { responseObj[key] = response; }; 
        data = data[key]
      }
      else {
        data = JSON.stringify(data);
      }
      break;
    case 'function': 
        callbackFunction = data; 
        data = '';
        break;
    default: break;
  }
  if (ui.responseCounter >= Number.MAX_SAFE_INTEGER-1) {
    ui.responseCounter = 0;
  }
  var storageIndex = ui.responseCounter++;
  ui.responseStorage[storageIndex] = new Object({'request': request, 'responseId': storageIndex, 'callbackFunction': callbackFunction});
  var jsonRequest = {'request': request, 'value': data, 'responseId': storageIndex, 'key': key};
  return jsonRequest;
};

/***
 * Generalized request post-processing
 * Maps the previous requestId to an object and applies the (async) response to this object
 ***/
ui.applyResponse = function(value, responseId) {
  var storedObject = ui.responseStorage[responseId];
  if (typeof storedObject.callbackFunction === 'function') {
    storedObject.callbackFunction(value);
  }
  delete ui.responseStorage[responseId];
};

/*global backend*/
ui.alert = function (str) {
  if (typeof backend === 'undefined') {
    alert(str);
  }
  else {
    backend.alert(str)
  }
}
ui.backend = function (request, data, callbackFunction) {
  if (typeof backend === 'undefined') {
  // Simulate running in Webview, but using a HTTP server
  // It will not be possible to use MS Edge for debugging, as this has similar identifiers as Webview on Windows 
  // query server with HTTP instead of calling webview callback
    var jsonRequest = ui.createRequest(request, data, callbackFunction);
    var stringRequest = JSON.stringify(jsonRequest);

    var opts = {
      method: 'POST',      
      mode: 'cors',
      cache: 'no-cache',
      headers: {'Content-Type': 'application/json'},
      body: stringRequest
    };
    if (defaultPostTarget == "") {
      var url = request; // Not required. Just for easier debugging
    }
    else {
      var url = defaultPostTarget; 
    }
    fetch(host + "/" + url, opts).then(function(response) { 
      return response.json();
    }).then(function(response) {
      var key = jsonRequest.key;
      if ((typeof response === "object") && (key in response)) {
        ui.applyResponse(response[key], jsonRequest.responseId);
      }
      else {
        ui.applyResponse(response, jsonRequest.responseId);
      }

    }).catch(function(err) {
      console.log(err);
    });
  }
  else {
    // This function is intendend to interact directly with webview. No HTTP server involved.
    // There will be an async call on the backend server, which is then triggering to call javascript from webview.
    // This callback function will be stored in a container ui.responseStorage. Nim Webview had issues calling javascript on Windows
    // at the time of development and therefore required an async approach.
      var jsonRequest = ui.createRequest(request, data, callbackFunction);
      var stringRequest = JSON.stringify(jsonRequest);
      backend.call(stringRequest);
    }
    ui.alert = function (str) {
      backend.alert(str)
    }
  }

// "import from" doesn't seem to work with webview here... So add this as global variable
window.ui = ui;