// vue.config.js
module.exports = {
  publicPath: '.',
  filenameHashing: false,
  devServer: {
    port: 5000, 
    proxy: 'http://127.0.0.1:8000'
  }
}