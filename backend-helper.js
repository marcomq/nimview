// This file is supposed to be copied automatically to the UI folder, if it doesn't exists there yet

let ui = {};
let defaultPostTarget = "";
ui.responseStorage = {};
ui.responseCounter = 0;
/***
 * Generalized request pre-processing
 * Creates a standartized json object to be sent to server and also stores an internal object to handle the response
 * 
 *  inputValue: will be sent to the server as json ".value"
 *  request: will be sent to server as json ".request"
 *  outputValueObj, will be used on client side, stores the object that might be modified with values from server
 *  outputValueIndex: will be used on client side, has the key to the values that are modified on client
 *  responeKey: is optional and may be used to re-map the server value; the default is outputValueIndex
 *  callbackFunction: is also optional and required if there is no automated Vue action when changing an object
 ***/
ui.createRequest = function(request, data, key, callbackFunction, responseKey) {
  let inputValue = "";
  if ((typeof key === 'undefined') || (key === "")) {
    key = request;
  }
  if (typeof data === 'object') {
    if (key in data) {
      inputValue = data[key];
    }
    else {
      // problem - no value in obj - value will be empty string instead of undefined
      if (console && console.log) {
        console.log("Key '" + key + "' not found in data of request:'" + request + "'")
      }
    }
  }
  else {
    inputValue = data;
  }
  if (typeof responseKey === 'undefined') {
    responseKey = key;
  }
  var storageIndex = ui.responseCounter++;
  if (storageIndex >= Number.MAX_SAFE_INTEGER-1) {
    storageIndex = 0;
  }
  ui.responseStorage[storageIndex] = new Object({'request': request, 'responseId': storageIndex, 'responseKey': responseKey, 'outputValueObj': data, 
                                                 'outputValueIndex': key, 'callbackFunction': callbackFunction}); // outputValueObj is stored as reference to apply modifications
  var jsonRequest = {'request': request, 'value': inputValue, 'responseId': storageIndex, 'responseKey': responseKey};
  return jsonRequest;
};

/***
 * Generalized request post-processing
 * Maps the previous requestId to an object and applies the (async) response to this object
 ***/
ui.applyResponse = function(value, responseId) {
  var storedObject = ui.responseStorage[responseId];
  if (typeof storedObject.callbackFunction == 'function') {
    storedObject.callbackFunction(value);
  }
  if (storedObject.responseKey && (typeof storedObject.outputValueObj !== 'undefined') 
      &&  (typeof storedObject.outputValueIndex !== 'undefined')) {
    storedObject.outputValueObj[storedObject.outputValueIndex] = value;
  }
  else {
    if (console && console.log) {
      console.log('error in response: ' + JSON.stringify(value) + ' of ' + JSON.stringify(storedObject));
    }
  }
  delete ui.responseStorage[responseId];
};


// There are some strange issues detecting webview in a clean way. So we just check if this is Chrom(e/ium) or Firefox and assume that we need ajax for those.
if ((navigator.userAgent.indexOf("Chrom") != -1) || (navigator.userAgent.indexOf("Firefox") != -1)) {
  // Simulate running in Webview, but using a HTTP server
  // It will not be possible to use MS Edge for debugging, as this has similar identifiers as Webview on Windows 
  // query server with HTTP instead of calling webview callback
  ui.alert = function (str) {
    alert(str)
  }
  ui.backend = function (request, data, key, callbackFunction, responseKey) {
    var jsonRequest = ui.createRequest(request, data, key, callbackFunction, responseKey);
    var stringRequest = JSON.stringify(jsonRequest);

    var opts = {
      method: 'POST',      
      mode: 'same-origin',
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
    fetch("/" + url, opts).then(function(response) { 
      return response.json();
    }).then(function(response) {
      responseKey = jsonRequest.responseKey;
      if ((typeof response === "object") && (responseKey in response)) {
        ui.applyResponse(response[responseKey], jsonRequest.responseId);
      }
      else {
        ui.applyResponse(response, jsonRequest.responseId);
      }
    })
    .catch(function(err) {
      console.log(err);
    });
  };
}
else {
  // This function is intendend to interact directly with webview. No HTTP server involved.
  // There will be an async call on the backend server, which is then triggering to call javascript from webview.
  // This callback function will be stored in a container ui.responseStorage. Nim Webview had issues calling javascript on Windows
  // at the time of development and therefore required an async approach.
  /*global backend*/
  ui.backend = function(request, data, key, callbackFunction, responseKey) {
    var jsonRequest = ui.createRequest(request, data, key, callbackFunction, responseKey);
    var stringRequest = JSON.stringify(jsonRequest);
    backend.call(stringRequest);
  }
  ui.alert = function (str) {
    backend.alert(str)
  }
}

// "import from" doesn't seem to work with webview here... So add this as global variable
window.ui = ui;