import svelte from 'rollup-plugin-svelte'
import resolve from '@rollup/plugin-node-resolve'
import commonjs from '@rollup/plugin-commonjs'
import livereload from 'rollup-plugin-livereload'
import { terser } from 'rollup-plugin-terser'
import dev from 'rollup-plugin-dev'
import json from 'rollup-plugin-json'
import babel from 'rollup-plugin-babel'
import copy from 'rollup-plugin-copy'
import css from 'rollup-plugin-css-only'


const production = !process.env.ROLLUP_WATCH

export default {
  input: 'src/main.js',
  output: {
    sourcemap: true,
    format: 'iife',
    name: 'app',
    file: 'dist/build/bundle.js'
  },
  plugins: [
    svelte({
      compilerOptions: {
        // enable run-time checks when not in production
        dev: !production
      }
    }),
		css({ output: 'bundle.css' }),
    // If you have external dependencies installed from
    // npm, you'll most likely need these plugins. In
    // some cases you'll need additional configuration 
    // consult the documentation for details:
    // https://github.com/rollup/rollup-plugin-commonjs
		resolve({
			browser: true,
			dedupe: ['svelte']
		}),
    commonjs(),
    json(), 

    // Watch the `dist` directory and refresh the
    // browser on changes when not in production
    !production && livereload('dist'),
    !production && dev({
      dirs: ['dist'],
      port: 5000, 
      proxy: { 
        '*': 'localhost:8000',
        '/*': 'localhost:8000/',
      }
    }),
    copy({
      targets: [{ 
        src: ['node_modules/bootstrap/dist/js/*.min.*', 'node_modules/bootstrap/dist/css/*.min.*'],
        dest: 'dist/vendor/bootstrap' 
      },{ 
        src: ['node_modules/jquery/dist/*.min.*'],
        dest: 'dist/vendor/jquery' 
      }],
      copyOnce: true
    }),

    // added by angelo
    // compile to good old IE11 compatible ES5
    babel({
      extensions: [ '.js', '.mjs', '.html', '.svelte' ],
      runtimeHelpers: true,
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