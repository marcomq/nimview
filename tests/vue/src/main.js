/** Nimview UI Library 
 * Copyright (C) 2020, 2021, by Marco Mengelkoch
 * Licensed under MIT License, see License file for more details
 * git clone https://github.com/marcomq/nimview
**/
import Vue from 'vue'
import App from './App.vue'
import BootstrapVue from 'bootstrap-vue'

import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
// backend-helper.js is loaded via HTML tag

Vue.use(BootstrapVue)
Vue.config.productionTip = false


// make this.backend() available for Vue
Vue.mixin({
  methods: {
    alert: str => window.ui.alert(str + ""),
    backend: function(request, data, callBackOrKey) {
      window.ui.backend(request, data , callBackOrKey);
      // alert('called nim');
    },
  }
})


new Vue({
  render: h => h(App),
}).$mount('#app')
