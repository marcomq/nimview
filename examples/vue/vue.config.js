// vue.config.js
module.exports = {
  publicPath: "",
  filenameHashing: false,
  devServer: {
    host: "localhost",
    port: 5000, 
    proxy: { 
      "/" : { target: 'http://localhost:8000'},
      "/ws" : { target: 'http://localhost:8000/ws', ws: false}
    }
  },
  transpileDependencies: [
    "nimview"
  ]
}