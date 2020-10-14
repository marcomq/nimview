import Vue from 'vue'
import App from './App.vue'
import BootstrapVue from 'bootstrap-vue'
import axios from "axios"
import './nimCall'

import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'

Vue.use(BootstrapVue)
Vue.config.productionTip = false

// there seems to be some issue on second start of webview - so check if this is webview and avoid loading javascript
if (typeof window.nim === "undefined" && (navigator.userAgent.indexOf("like Gecko") == -1) && (navigator.userAgent.indexOf("Edg") == -1)) {
  // query server with HTTP instead of calling webview callback
  window.nim = {}
  window.nim.alert = function (str) {
    alert(str)
  }
  window.ui.nimCall = function (inputValue, outputValueObj, outputValueIndex, request, responseKey, callbackFunction) {
    var jsonRequest = window.ui.callAndCreateRequest(inputValue, outputValueObj, outputValueIndex, request, responseKey, callbackFunction)
    axios
    .get('127.0.0.1:8000/?' + jsonRequest)
    .then(response => {
      window.ui.applyResponse(response["responseKey"], jsonRequest.responseId);
    })
    .catch(err => {
      console.log(err);
    });
  }
}

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
