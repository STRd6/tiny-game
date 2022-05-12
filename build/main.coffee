esbuild = require 'esbuild'

watch = process.argv.includes '--watch'
minify = !watch || process.argv.includes '--minify'
sourcemap = true

esbuild.build({
  entryPoints: ['dist/index.js']
  tsconfig: "./tsconfig.json"
  bundle: true
  sourcemap
  minify
  watch
  platform: 'browser'
  outfile: 'dist/tiny-game.js'
  globalName: 'TinyGame'
  plugins: [  ]
}).catch -> process.exit 1
