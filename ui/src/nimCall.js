// uses axios in case of debugging or when using HTTP server instead of webview
import axios from "axios"

export let ui = {}
export let nim = {}
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
ui.callAndCreateRequest = function(request, data, key, responseKey, callbackFunction) {
  let inputValue = ""
  if (typeof data === 'object') {
    if (key in data) {
      inputValue = data[key];
    }
    else {
      // problem - no value in obj - value will be empty string instead of undefined
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
}

/***
 * Generalized request post-processing
 * Maps the previous requestId to an object and applies the response to this object
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
}


if (typeof window.nim === "undefined" && (navigator.userAgent.indexOf("Trident") == -1) && (navigator.userAgent.indexOf("Edg") == -1)) {
  // Simulate running in Webview, but using a HTTP server
  // There seems to be some issue on second start of webview - so check if this is webview and avoid loading specific javascript
  // It will not be possible to use MS Edge for debugging, as this has similar identifiers as Webview on Windows 
  // query server with HTTP instead of calling webview callback
  nim = {}
  nim.alert = function (str) {
    alert(str)
  }
  ui.nimCall = function (request, inputValue, outputValueObj, outputValueIndex, responseKey, callbackFunction) {
    var jsonRequest = window.ui.callAndCreateRequest(request, inputValue, outputValueObj, outputValueIndex, responseKey, callbackFunction);
    var stringRequest = JSON.stringify(jsonRequest);
    axios
    .get("/" + stringRequest)
    .then(response => {
      responseKey = jsonRequest.responseKey;
      if ((typeof response.data === "object") && (responseKey in response.data)) {
        window.ui.applyResponse(response.data[responseKey], jsonRequest.responseId);
      }
      else {
        window.ui.applyResponse(response.data, jsonRequest.responseId);
      }
    })
    .catch(err => {
      console.log(err);
    });
  }
}
else {
  // This function is intendend to interact directly with webview. No HTTP server involved.
  // There will be an async call on the nim server, which is then triggering to call javascript from webview.
  // This callback function will be stored in a container ui.responseStorage. Nim Webview had issues calling javascript on Windows
  // at the time of development and therefore required an async approach.
  ui.nimCall = function(request, inputValue, outputValueObj, outputValueIndex, responseKey, callbackFunction) {
    var jsonRequest = ui.callAndCreateRequest(request, inputValue, outputValueObj, outputValueIndex, responseKey, callbackFunction);
    var stringRequest = JSON.stringify(jsonRequest);
    window.nim.call(stringRequest);
  }
}

window.ui = ui;
window.nim = nim;