import Vue from 'vue'
import App from './App.vue'
import BootstrapVue from 'bootstrap-vue'
import './nimCall'

import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'

Vue.use(BootstrapVue)
Vue.config.productionTip = false


// make this.nimCall() available for Vue
Vue.mixin({
  methods: {
    alert: str => window.nim.alert(str + ""),
    nimCall: function(request, inputValue, outputValueObj, outputValueIndex, responseKey, callbackFunction) {
      window.ui.nimCall(request, inputValue, outputValueObj, outputValueIndex, responseKey, callbackFunction);
      // alert('called nim');
    },
  }
})


new Vue({
  render: h => h(App),
}).$mount('#app')
