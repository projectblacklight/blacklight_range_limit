'use strict'

import includePaths from 'rollup-plugin-includepaths';

import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const BUNDLE = process.env.BUNDLE === 'true'
const ESM = process.env.ESM === 'true'

const fileDest = `range_limit${ESM ? '.esm' : '.umd'}`
const external = []
const globals = {}

let includePathOptions = {
  include: {},
  paths: ['app/javascript'],
  external: [],
  extensions: ['.js']
};

const rollupConfig = {
  input: resolve(__dirname, `app/javascript/range_limit/index.js`),
  output: {
    file: resolve(__dirname, `app/assets/javascripts/blacklight_range_limit/${fileDest}.js`),
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

export default rollupConfig
