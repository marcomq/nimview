/*
This function is intendend to interact with webview.
There will be an async call on the nim server, which is then triggering to call javascript from webview.
This callback function will be stored in a container ui.responseStorage. Nim Webview had issues calling javascript on Windows
 at the time of development and therefore required an async approach.
*/

export let ui = {}
ui.responseStorage = {};
ui.responseCounter = 0;
/***
 *  inputValue: will be sent to the server as json ".value"
 *  request: will be sent to server as json ".request"
 *  outputValueObj, will be used on client side, stores the object that might be modified with values from server
 *  outputValueIndex: will be used on client side, has the key to the values that are modified on client
 *  responeKey: is optional and may be used to re-map the server value; the default is outputValueIndex
 *  callbackFunction: is also optional and required if there is no automated Vue action when changing an object
 ***/
ui.callAndCreateRequest = function(inputValue, outputValueObj, outputValueIndex, request, responseKey, callbackFunction) {
  if (typeof request === 'undefined') {
    request = '';
  }
  if (typeof responseKey === 'undefined') {
    responseKey = outputValueIndex;
  }
  var storageIndex = ui.responseCounter++;
  if (storageIndex >= Number.MAX_SAFE_INTEGER-1) {
    storageIndex = 0;
  }
  ui.responseStorage[storageIndex] = new Object({'request': request, 'responseId': storageIndex, 'responseKey': responseKey, 'outputValueObj': outputValueObj, 
                                                 'outputValueIndex': outputValueIndex, 'callbackFunction': callbackFunction}); // outputValueObj is stored as reference to apply modifications
  var jsonRequest = {'request': request, 'responseId': storageIndex, 'responseKey': responseKey, 'value': inputValue};
  return jsonRequest;
}

ui.nimCall = function(inputValue, outputValueObj, outputValueIndex, request, responseKey, callbackFunction) {
  var jsonRequest = ui.callAndCreateRequest(inputValue, outputValueObj, outputValueIndex, request, responseKey, callbackFunction);
  var stringRequest = JSON.stringify(jsonRequest);
  window.nim.call(stringRequest);
}

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
    console.log('error in response: ' + JSON.stringify(value) + ' of ' + JSON.stringify(storedObject))
  }
  delete ui.responseStorage[responseId];
}
window.ui = ui;