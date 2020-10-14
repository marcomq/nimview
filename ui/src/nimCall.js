export let ui = {}
ui.responseStorage = {};
ui.responseCounter = 0;
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
  window.nim.call(JSON.stringify(jsonRequest));
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