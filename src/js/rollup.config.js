import resolve from '@rollup/plugin-node-resolve'
import { terser } from 'rollup-plugin-terser'
import { babel } from '@rollup/plugin-babel'
import commonjs from '@rollup/plugin-commonjs'


const production = !process.env.ROLLUP_WATCH
const babelCfg = {
  extensions: [ '.js'],
  babelHelpers: 'runtime',
  exclude: [ 'node_modules/@babel/**', 'node_modules/core-js/**' ],
  presets: [
    [
      '@babel/preset-env',
      {
        targets: {
          ie: '11'
        },
        useBuiltIns: 'usage',
        corejs: 2
      }
    ]
  ],
  plugins: [
    '@babel/plugin-syntax-dynamic-import',
    [
      '@babel/plugin-transform-runtime',
      {
        "absoluteRuntime": false
      }
    ]
  ]
}
export default {
  input: 'nimview.js',
  output: [{
    sourcemap: true,
    format: 'cjs',
    name: 'nimview_js',
    file: 'nimview.cjs.js',
    exports: 'auto'
  }, {
    sourcemap: true,
    format: 'esm',
    name: 'nimview_js',
    file: 'nimview.esm.js',
    exports: 'auto'
  }, {
    sourcemap: true,
    format: 'iife',
    name: 'nimview_js',
    file: 'nimview.iife.js',
    exports: 'auto'
  }], 
  plugins: [
    resolve({
      browser: true
    }),
    commonjs(),
    babel(babelCfg),
    production && terser()
  ],
  watch: {
    clearScreen: false
  }
}