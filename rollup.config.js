'use strict'

import includePaths from 'rollup-plugin-includepaths';

const path = require('path')

const BUNDLE = process.env.BUNDLE === 'true'
const ESM = process.env.ESM === 'true'

const fileDest = `blacklight_range_limit${ESM ? '.esm' : '.umd'}`
const external = []
const globals = {}

let includePathOptions = {
  include: {},
  paths: ['app/javascript'],
  external: [],
  extensions: ['.js']
};

const rollupConfig = {
  input: path.resolve(__dirname, `app/javascript/blacklight_range_limit/index.js`),
  output: {
    file: path.resolve(__dirname, `app/assets/javascripts/blacklight_range_limit/${fileDest}.js`),
    format: ESM ? 'esm' : 'umd',
    globals,
    generatedCode: 'es2015'
  },
  external,
  plugins: [includePaths(includePathOptions)]
}

if (!ESM) {
  rollupConfig.output.name = 'BlacklightRangeLimit'
}

module.exports = rollupConfig
