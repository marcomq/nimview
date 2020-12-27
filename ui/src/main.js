import Vue from 'vue'
import App from './App.vue'
import BootstrapVue from 'bootstrap-vue'

import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
import './webviewBackend' // "import from" doesn't seem to work with webview here... Let me know if you find some better solution

Vue.use(BootstrapVue)
Vue.config.productionTip = false


// make this.nimCall() available for Vue
Vue.mixin({
  methods: {
    alert: str => window.ui.alert(str + ""),
    backend: function(request, inputValue, outputValueObj, outputValueIndex, responseKey, callbackFunction) {
      window.ui.backend(request, inputValue, outputValueObj, outputValueIndex, responseKey, callbackFunction);
      // alert('called nim');
    },
  }
})


new Vue({
  render: h => h(App),
}).$mount('#app')
