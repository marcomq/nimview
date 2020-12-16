import Vue from 'vue'
import App from './App.vue'
import BootstrapVue from 'bootstrap-vue'
import axios from "axios"
import './nimCall'

import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'

Vue.use(BootstrapVue)
Vue.config.productionTip = false

// Simulate running in Webview, but using a HTTP server
// There seems to be some issue on second start of webview - so check if this is webview and avoid loading specific javascript
// It will not be possible to use MS Edge for debugging, as this has similar identifiers as Webview on Windows 
if (typeof window.nim === "undefined" && (navigator.userAgent.indexOf("Trident") == -1) && (navigator.userAgent.indexOf("Edg") == -1)) {
  // query server with HTTP instead of calling webview callback
  window.nim = {}
  window.nim.alert = function (str) {
    alert(str)
  }
  window.ui.nimCall = function (inputValue, outputValueObj, outputValueIndex, request, responseKey, callbackFunction) {
    var jsonRequest = window.ui.callAndCreateRequest(inputValue, outputValueObj, outputValueIndex, request, responseKey, callbackFunction);
    var stringRequest = JSON.stringify(jsonRequest);
    axios
    .get("/" + stringRequest)
    .then(response => {
      window.ui.applyResponse(response.data, jsonRequest.responseId);
    })
    .catch(err => {
      console.log(err);
    });
  }
}

// make this.nimCall() available for Vue
Vue.mixin({
  methods: {
    alert: str => window.nim.alert(str + ""),
    nimCall: function(inputValue, outputValueObj, outputValueIndex, request, responseKey, callbackFunction) {
      window.ui.nimCall(inputValue, outputValueObj, outputValueIndex, request, responseKey, callbackFunction);
      // alert('called nim');
    },
  }
})


new Vue({
  render: h => h(App),
}).$mount('#app')
