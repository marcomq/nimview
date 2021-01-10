// vue.config.js
module.exports = {
  publicPath: '.',
  filenameHashing: false,
  devServer: {
	proxy: 'http://127.0.0.1:8000'
  }
}