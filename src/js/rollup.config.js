import { nodeResolve } from '@rollup/plugin-node-resolve'
import { terser } from 'rollup-plugin-terser'
import { babel } from '@rollup/plugin-babel'
import commonjs from '@rollup/plugin-commonjs'


const production = !process.env.ROLLUP_WATCH

export default {
  input: 'nimview_ems.js',
  output: {
    sourcemap: true,
    format: 'cjs',
    name: 'nimview',
    file: 'nimview.js',
    exports: 'default'
  },
  plugins: [
    // If you have external dependencies installed from
    // npm, you'll most likely need these plugins. In
    // some cases you'll need additional configuration 
    // consult the documentation for details:
    // https://github.com/rollup/rollup-plugin-commonjs
		nodeResolve({
			browser: true
		}),
    commonjs(),
    // compile to good old IE11 compatible ES5
    babel({
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
            corejs: 3
          }
        ]
      ],
      plugins: [
        '@babel/plugin-syntax-dynamic-import',
        [
          '@babel/plugin-transform-runtime',
          {
            useESModules: true
          }
        ]
      ]
    }),

    // If we're building for production (npm run build
    // instead of npm run dev), minify
    production && terser()
  ],
  watch: {
    clearScreen: false
  }
}