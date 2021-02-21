// vue.config.js
module.exports = {
  devServer: { 
    port: 5000 
  },
  publicPath: '.',
  filenameHashing: false,
  devServer: {
	proxy: 'http://127.0.0.1:8000'
  }
}