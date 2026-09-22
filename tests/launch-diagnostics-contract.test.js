'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const html = fs.readFileSync(
  path.join(__dirname, '..', 'index-embedded.html'),
  'utf8'
);

assert(html.includes('window.__awLaunchFailure = null;'),
  'launch failure state is missing');
assert(html.includes("window.addEventListener('error'"),
  'JavaScript startup errors are not observed');
assert(html.includes("window.addEventListener('unhandledrejection'"),
  'startup promise rejections are not observed');
assert(html.includes('AETHERWAKE COULD NOT START'),
  'visible startup-failure panel copy is missing');
assert(html.includes("window._setupOrder.indexOf('setup-done') !== -1"),
  'loading gate does not require setup-done');
assert(html.includes("showLaunchFailure(\n          'Startup timeout'"),
  'startup timeout does not fail visibly');
assert(!html.includes("console.warn('[launch] force-revealing after"),
  'launch gate still force-reveals an uninitialized runtime');

console.log('Aetherwake launch diagnostics contract: PASS');
